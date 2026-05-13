const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { setSecurityContext } = require("./db");

const cookieName = "secure_cart_session";

function signSession(user) {
  return jwt.sign(
    {
      userId: user.UserID,
      role: user.Role,
      email: user.Email,
      name: `${user.FirstName} ${user.LastName}`
    },
    process.env.JWT_SECRET,
    { expiresIn: "2h" }
  );
}

function verifySession(token) {
  if (!token) return null;
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    return null;
  }
}

async function comparePassword(password, passwordHash) {
  return bcrypt.compare(password, passwordHash);
}

function requireAuth(roles = []) {
  return async (req, res, next) => {
    const user = verifySession(req.cookies[cookieName]);
    if (!user) return res.status(401).json({ error: "Authentication required" });
    if (roles.length > 0 && !roles.includes(user.role)) {
      return res.status(403).json({ error: "Access denied" });
    }
    req.user = user;
    try {
      await setSecurityContext(user);
      return next();
    } catch (error) {
      return next(error);
    }
  };
}

module.exports = { cookieName, signSession, verifySession, comparePassword, requireAuth };
