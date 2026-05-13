const express = require("express");
const { z } = require("zod");
const { sql, getPool, query, audit } = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();

const orderSchema = z.object({
  productId: z.string().min(3),
  quantity: z.number().int().positive(),
  shippingAddress: z.string().min(10).max(255)
});

router.get("/", requireAuth(["Customer", "Admin"]), async (req, res, next) => {
  try {
    const isAdmin = req.user.role === "Admin";
    const result = await query(
      `SELECT o.OrderID, o.UserID, o.TotalAmount, o.Status, o.ShippingAddress, o.CreatedAt,
              oi.ProductID, oi.Quantity, oi.UnitPrice, p.Name AS ProductName
       FROM CustomerOrder o
       INNER JOIN OrderItem oi ON o.OrderID = oi.OrderID
       INNER JOIN Product p ON oi.ProductID = p.ProductID
       WHERE (@isAdmin = 1 OR o.UserID = @userId)
       ORDER BY o.CreatedAt DESC`,
      {
        isAdmin: { type: sql.Bit, value: isAdmin },
        userId: { type: sql.NVarChar(50), value: req.user.userId }
      }
    );
    res.json({ orders: result.recordset });
  } catch (error) {
    next(error);
  }
});

router.post("/", requireAuth(["Customer"]), async (req, res, next) => {
  const pool = await getPool();
  const transaction = new sql.Transaction(pool);

  try {
    const body = orderSchema.parse(req.body);
    const orderId = `ORD-${Date.now()}`;

    await transaction.begin();
    const request = new sql.Request(transaction);
    request.input("productId", sql.NVarChar(50), body.productId);
    const productResult = await request.query(
      `SELECT ProductID, Price, StockQty
       FROM Product WITH (UPDLOCK, ROWLOCK)
       WHERE ProductID = @productId AND IsActive = 1`
    );

    const product = productResult.recordset[0];
    if (!product || product.StockQty < body.quantity) {
      await transaction.rollback();
      return res.status(400).json({ error: "Product unavailable or insufficient stock" });
    }

    const total = Number(product.Price) * body.quantity;
    const orderRequest = new sql.Request(transaction);
    orderRequest.input("orderId", sql.NVarChar(50), orderId);
    orderRequest.input("userId", sql.NVarChar(50), req.user.userId);
    orderRequest.input("total", sql.Decimal(18, 2), total);
    orderRequest.input("shippingAddress", sql.NVarChar(255), body.shippingAddress);
    orderRequest.input("productId", sql.NVarChar(50), body.productId);
    orderRequest.input("quantity", sql.Int, body.quantity);
    orderRequest.input("unitPrice", sql.Decimal(18, 2), product.Price);

    await orderRequest.query(
      `INSERT INTO CustomerOrder (OrderID, UserID, TotalAmount, Status, ShippingAddress)
       VALUES (@orderId, @userId, @total, 'Pending', @shippingAddress);

       INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice)
       VALUES (@orderId, @productId, @quantity, @unitPrice);

       UPDATE Product
       SET StockQty = StockQty - @quantity, UpdatedAt = SYSUTCDATETIME()
       WHERE ProductID = @productId;`
    );

    await transaction.commit();
    await audit({
      actorId: req.user.userId,
      actorRole: req.user.role,
      action: "OrderCreated",
      targetType: "Order",
      targetId: orderId,
      status: "Success",
      ipAddress: req.ip
    });

    res.status(201).json({ orderId, total });
  } catch (error) {
    if (transaction._aborted !== true) {
      try {
        await transaction.rollback();
      } catch {
        // Ignore rollback failure after SQL Server has already aborted the transaction.
      }
    }
    if (error instanceof z.ZodError) return res.status(400).json({ error: "Invalid order data" });
    return next(error);
  }
});

module.exports = router;
