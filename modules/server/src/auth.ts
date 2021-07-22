import express from "express";

import { env } from "./env";
import { logger } from "./utils";

const log = logger.child({ module: "Auth" });

export const authRouter = express.Router();

const authHeaderKey = "authorization";
const authType = "Basic";
const encodedToken = Buffer.from(`${env.authUsername}:${env.authPassword}`).toString("base64");

const restrictedMethods = ["DELETE", "POST", "PUT"];
const restrictedPaths = ["/auth", "/ipfs", "/media"];

authRouter.use((req, res, next) => {
  if (restrictedPaths.includes(req.path) || restrictedMethods.includes(req.method)) {
    const authHeader = req.headers[authHeaderKey];
    if (!req.headers[authHeaderKey] || authHeader !== `${authType} ${encodedToken}`) {
      if (req.path === "/auth") {
        res.removeHeader("www-authenticate"); // prevents browser from popping up a login window.
      } else {
        res.setHeader("www-authenticate", authType);
      }
      // Log a description re why auth failed
      const prefix = `Failed to auth ${req.method} to ${req.path}`;
      if (!authHeader) {
        log.warn(`${prefix}, no ${authHeaderKey} header provided.`);
      } else if (!authHeader.includes(" ")) {
        log.warn(`${prefix}, invalid auth header format. Got: "${authHeader}"`);
      } else if (!authHeader.startsWith(`${authType} `)) {
        log.warn(`${prefix}, invalid auth type. Got ${authHeader.split(" ")[0]} (!== ${authType})`);
      } else {
        const givenToken = Buffer.from(authHeader.split(" ")[1]!, "base64").toString("utf8");
        if (!givenToken || !givenToken.includes(":")) {
          log.warn(`${prefix}, invalid token format. Got: "${givenToken}"`);
        } else {
          const givenUser = givenToken.split(":")[0];
          const givenPassword = givenToken.split(":")[1];
          if (env.authUsername !== givenUser) {
            log.warn(`${prefix}, invalid username. Got: ${givenUser} (!= ${env.authUsername})`);
          } else if (env.authPassword !== givenPassword)  {
            log.warn(`${prefix}, invalid password. Got: ${givenPassword} (!= ${env.authPassword})`);
          } else {
            log.warn(`${prefix}, unknown error verifying token: ${givenToken}`);
          }
        }
      }
      res.status(401).send("Unauthorized");
    } else {
      log.info(`Successfully authenticated ${req.method} to ${req.path}`);
      next();
    }
  } else {
    log.debug(`Authentication not required for ${req.method} to ${req.path}`);
    next();
  }
});
