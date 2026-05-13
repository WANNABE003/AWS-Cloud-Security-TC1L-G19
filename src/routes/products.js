const express = require("express");
const { z } = require("zod");
const { sql, query, audit } = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();

const productSchema = z.object({
  name: z.string().min(2).max(120),
  sku: z.string().min(3).max(40),
  price: z.number().positive(),
  stockQty: z.number().int().min(0),
  category: z.string().min(2).max(80)
});

router.get("/", requireAuth(["Customer", "InventoryOfficer", "Admin"]), async (req, res, next) => {
  try {
    const result = await query(
      `SELECT ProductID, Name, SKU, Price, StockQty, Category, IsActive, CreatedAt
       FROM Product
       WHERE IsActive = 1
       ORDER BY CreatedAt DESC`
    );
    res.json({ products: result.recordset });
  } catch (error) {
    next(error);
  }
});

router.post("/", requireAuth(["InventoryOfficer", "Admin"]), async (req, res, next) => {
  try {
    const body = productSchema.parse(req.body);
    const productId = `PRD-${Date.now()}`;

    await query(
      `INSERT INTO Product (ProductID, Name, SKU, Price, StockQty, Category, CreatedBy)
       VALUES (@productId, @name, @sku, @price, @stockQty, @category, @createdBy)`,
      {
        productId: { type: sql.NVarChar(50), value: productId },
        name: { type: sql.NVarChar(120), value: body.name },
        sku: { type: sql.NVarChar(40), value: body.sku },
        price: { type: sql.Decimal(18, 2), value: body.price },
        stockQty: { type: sql.Int, value: body.stockQty },
        category: { type: sql.NVarChar(80), value: body.category },
        createdBy: { type: sql.NVarChar(50), value: req.user.userId }
      }
    );

    await audit({
      actorId: req.user.userId,
      actorRole: req.user.role,
      action: "ProductCreated",
      targetType: "Product",
      targetId: productId,
      status: "Success",
      ipAddress: req.ip
    });

    res.status(201).json({ productId });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: "Invalid product data" });
    return next(error);
  }
});

router.delete("/:id", requireAuth(["Admin"]), async (req, res, next) => {
  try {
    const result = await query(
      `UPDATE Product
       SET IsActive = 0, UpdatedAt = SYSUTCDATETIME()
       WHERE ProductID = @productId`,
      { productId: { type: sql.NVarChar(50), value: req.params.id } }
    );

    await audit({
      actorId: req.user.userId,
      actorRole: req.user.role,
      action: "ProductDeleted",
      targetType: "Product",
      targetId: req.params.id,
      status: result.rowsAffected[0] === 1 ? "Success" : "NotFound",
      ipAddress: req.ip
    });

    if (result.rowsAffected[0] !== 1) return res.status(404).json({ error: "Product not found" });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
