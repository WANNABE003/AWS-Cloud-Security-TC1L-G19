const express = require("express");
const { z } = require("zod");
const { sql, query, audit } = require("../db");
const { cookieName, signSession, comparePassword, requireAuth } = require("../auth");
const { loginLimiter } = require("../middleware/security");

const router = express.Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8)
});

router.post("/login", loginLimiter, async (req, res, next) => {
  try {
    const body = loginSchema.parse(req.body);
    const result = await query(
      `SELECT UserID, Role, Email, FirstName, LastName, PasswordHash, IsActive
       FROM AppUser
       WHERE Email = @email`,
      { email: { type: sql.NVarChar(255), value: body.email.toLowerCase() } }
    );

    const user = result.recordset[0];
    const valid = user && user.IsActive && (await comparePassword(body.password, user.PasswordHash));

    await audit({
      actorId: user?.UserID,
      actorRole: user?.Role || "Guest",
      action: "Login",
      targetType: "User",
      targetId: user?.UserID,
      status: valid ? "Success" : "Failed",
      ipAddress: req.ip
    });

    if (!valid) return res.status(401).json({ error: "Invalid credentials" });

    res.cookie(cookieName, signSession(user), {
      httpOnly: true,
      sameSite: "strict",
      secure: process.env.NODE_ENV === "production",
      maxAge: 2 * 60 * 60 * 1000
    });

    return res.json({
      user: {
        userId: user.UserID,
        role: user.Role,
        email: user.Email,
        name: `${user.FirstName} ${user.LastName}`
      }
    });
  } catch (error) {
    if (error instanceof z.ZodError) return res.status(400).json({ error: "Invalid login payload" });
    return next(error);
  }
});

router.post("/logout", requireAuth(), async (req, res, next) => {
  try {
    await audit({
      actorId: req.user.userId,
      actorRole: req.user.role,
      action: "Logout",
      targetType: "User",
      targetId: req.user.userId,
      status: "Success",
      ipAddress: req.ip
    });
    res.clearCookie(cookieName);
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

router.get("/me", requireAuth(), (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
