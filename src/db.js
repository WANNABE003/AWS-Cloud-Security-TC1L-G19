const { Pool } = require("pg");
const fs = require("fs");

const host = process.env.DB_HOST || process.env.DB_SERVER || "localhost";
const user = process.env.DB_USER || "postgres";
const password = process.env.DB_PASSWORD;
const database = process.env.DB_DATABASE || "secureecommerce";
const port = parseInt(process.env.DB_PORT || "5432", 10);

if (!password) throw new Error("DB_PASSWORD is required");

const poolConfig = {
  user,
  host,
  database,
  password,
  port,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
};

// Enable SSL/TLS encryption for RDS in transit (Data Protection requirement)
if (process.env.NODE_ENV === "production" || process.env.DB_SSL === "true") {
  poolConfig.ssl = {
    rejectUnauthorized: true,
    ...(process.env.DB_SSL_CA ? { ca: fs.readFileSync(process.env.DB_SSL_CA, "utf8") } : {})
  };
}

const pool = new Pool(poolConfig);

const canonicalColumnNames = new Map([
  "userid", "UserID", "role", "Role", "email", "Email", "firstname", "FirstName",
  "lastname", "LastName", "phonenumber", "PhoneNumber", "addressline1", "AddressLine1",
  "city", "City", "state", "State", "postcode", "Postcode", "passwordhash", "PasswordHash",
  "isactive", "IsActive", "createdat", "CreatedAt", "updatedat", "UpdatedAt",
  "productid", "ProductID", "name", "Name", "sku", "SKU", "price", "Price",
  "stockqty", "StockQty", "category", "Category", "createdby", "CreatedBy",
  "orderid", "OrderID", "totalamount", "TotalAmount", "status", "Status",
  "shippingaddress", "ShippingAddress", "orderitemid", "OrderItemID", "quantity", "Quantity",
  "unitprice", "UnitPrice", "productname", "ProductName", "auditid", "AuditID",
  "eventtime", "EventTime", "actorid", "ActorID", "actorrole", "ActorRole",
  "action", "Action", "targettype", "TargetType", "targetid", "TargetID", "ipaddress", "IpAddress"
].reduce((pairs, value, index, values) => {
  if (index % 2 === 0) pairs.push([value, values[index + 1]]);
  return pairs;
}, []));

function normalizeRows(rows) {
  return rows.map((row) => Object.fromEntries(
    Object.entries(row).map(([key, value]) => [canonicalColumnNames.get(key) || key, value])
  ));
}

function translateQuery(text, params = {}) {
  let pgText = text;
  const pgValues = [];
  let index = 1;

  // Sort parameters by length descending to prevent sub-string replacement bugs (e.g. @productId replacing @product)
  const sortedNames = Object.keys(params).sort((a, b) => b.length - a.length);

  for (const name of sortedNames) {
    const param = params[name];
    const value = param && typeof param === "object" && "value" in param ? param.value : param;
    const regex = new RegExp("@" + name + "\\b", "g");
    if (regex.test(pgText)) {
      pgText = pgText.replace(regex, `$${index}`);
      pgValues.push(value);
      index++;
    }
  }

  // Translate common SQL Server expressions to PostgreSQL
  pgText = pgText.replace(/DATEADD\s*\(\s*HOUR\s*,\s*8\s*,\s*(SYSUTCDATETIME\(\)|GETDATE\(\))\)/gi, "(NOW() + INTERVAL '8 hours')");
  pgText = pgText.replace(/SYSUTCDATETIME\(\)/gi, "(NOW() + INTERVAL '8 hours')");
  pgText = pgText.replace(/WITH\s*\(UPDLOCK\s*,\s*ROWLOCK\s*\)/gi, "FOR UPDATE");

  return { text: pgText, values: pgValues };
}

async function query(text, params = {}) {
  const { text: pgText, values } = translateQuery(text, params);
  const result = await pool.query(pgText, values);
  const rows = normalizeRows(result.rows);
  return {
    recordset: rows,
    rows,
    rowsAffected: [result.rowCount],
    rowCount: result.rowCount
  };
}

async function audit({ actorId, actorRole, action, targetType, targetId, status, ipAddress }) {
  await query(
    `INSERT INTO AuditLog (EventTime, ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress)
     VALUES (NOW() + INTERVAL '8 hours', @actorId, @actorRole, @action, @targetType, @targetId, @status, @ipAddress)`,
    {
      actorId: actorId || "anonymous",
      actorRole: actorRole || "Guest",
      action,
      targetType,
      targetId: targetId || null,
      status,
      ipAddress: ipAddress || null
    }
  );
}

// Mock mssql types and interfaces to keep compatibility in code routes
const sql = {
  NVarChar: () => "VARCHAR",
  Int: () => "INTEGER",
  Decimal: () => "DECIMAL",
  Bit: () => "BOOLEAN",
  DateTime2: () => "TIMESTAMP",
  Transaction: class {
    constructor(p) {
      this.pool = p || pool;
      this.client = null;
    }
    async begin() {
      this.client = await this.pool.connect();
      await this.client.query("BEGIN");
    }
    async commit() {
      await this.client.query("COMMIT");
      this.client.release();
    }
    async rollback() {
      await this.client.query("ROLLBACK");
      this.client.release();
    }
  },
  Request: class {
    constructor(transaction) {
      this.transaction = transaction;
      this.params = {};
    }
    input(name, type, value) {
      this.params[name] = { value };
    }
    async query(text) {
      const { text: pgText, values } = translateQuery(text, this.params);
      let res;
      if (this.transaction && this.transaction.client) {
        res = await this.transaction.client.query(pgText, values);
      } else {
        res = await pool.query(pgText, values);
      }
      const rows = normalizeRows(res.rows);
      return {
        recordset: rows,
        rows,
        rowsAffected: [res.rowCount]
      };
    }
  }
};

module.exports = { sql, query, audit, getPool: () => pool };
