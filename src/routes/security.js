const express = require("express");
const { sql, query } = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();

router.get("/audit", requireAuth(["Admin"]), async (req, res, next) => {
  try {
    const result = await query(
      `SELECT TOP (50) AuditID, EventTime, ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress
       FROM AuditLog
       ORDER BY EventTime DESC`
    );
    res.json({ auditLogs: result.recordset });
  } catch (error) {
    next(error);
  }
});

router.get("/masked-customers", requireAuth(["InventoryOfficer", "Admin"]), async (req, res, next) => {
  try {
    const result = await query(
      `SELECT UserID, Role, Email, FirstName, LastName, PhoneNumber, AddressLine1, City, State
       FROM vw_CustomersForStaff
       WHERE (@isAdmin = 1 OR Role = 'Customer')`,
      { isAdmin: { type: sql.Bit, value: req.user.role === "Admin" } }
    );
    res.json({ customers: result.recordset });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
