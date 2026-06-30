const express = require("express");
const { sql, query } = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();

router.get("/audit", requireAuth(["Admin"]), async (req, res, next) => {
  try {
    const result = await query(
      `SELECT AuditID, EventTime, ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress
       FROM AuditLog
       ORDER BY EventTime DESC
       LIMIT 50`
    );
    res.json({ auditLogs: result.recordset });
  } catch (error) {
    next(error);
  }
});

router.get("/masked-customers", requireAuth(["InventoryOfficer", "Admin"]), async (req, res, next) => {
  try {
    const result = await query(
      `SELECT UserID, Role, Email, FirstName, LastName,
              CASE WHEN @isAdmin THEN PhoneNumber
                   WHEN PhoneNumber IS NULL THEN NULL
                   ELSE SUBSTRING(PhoneNumber FROM 1 FOR 2) || 'XXXXXX' || RIGHT(PhoneNumber, 2) END AS PhoneNumber,
              CASE WHEN @isAdmin THEN AddressLine1
                   WHEN AddressLine1 IS NULL THEN NULL
                   ELSE LEFT(AddressLine1, 4) || 'XXXXXX' END AS AddressLine1,
              City, State
       FROM AppUser
       WHERE Role = 'Customer'`,
      { isAdmin: { type: sql.Bit, value: req.user.role === "Admin" } }
    );

    res.json({ customers: result.recordset });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
