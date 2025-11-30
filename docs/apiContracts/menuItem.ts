import { Router } from "express";
import {
  authenticate,
  validateBody,
  validateParams,
} from "../../../../platform/http/middleware/index.js";

import { uploadSingleImage } from "../../../../platform/http/middleware/multer.js";
import { uploadOptionalSingleImage } from "../../../../platform/http/middleware/multer.js";
import { handleMulterError } from "../../../../platform/http/middleware/multer.js";

import { MenuItemController } from "../controller/index.js";
import {
  createMenuItemSchema,
  updateMenuItemSchema,
  menuItemIdParamSchema,
} from "../schemas/schemas.js";

const menuItemRouter = Router();

/**
 * @openapi
 * /v1/menu/items/by-branch:
 *   get:
 *     summary: List menu items for a specific branch
 *     tags:
 *       - MenuItems
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: query
 *         name: branchId
 *         required: true
 *         schema:
 *           type: string
 *         description: Branch ID
 *     responses:
 *       200:
 *         description: List of menu items for the branch
 *       400:
 *         description: Invalid input
 *       401:
 *         description: Unauthorized
 */
menuItemRouter.get(
  "/v1/menu/items/by-branch",
  authenticate,
  MenuItemController.listByBranch
);

/**
 * @openapi
 * /v1/menu/items:
 *   post:
 *     summary: Create a new menu item
 *     tags:
 *       - MenuItems
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - categoryId
 *               - branchId
 *               - name
 *               - priceUsd
 *             properties:
 *               categoryId:
 *                 type: string
 *                 format: uuid
 *                 description: Category ID
 *               branchId:
 *                 type: string
 *                 format: uuid
 *                 description: Branch ID
 *               name:
 *                 type: string
 *                 description: Menu item name
 *               description:
 *                 type: string
 *                 description: Menu item description
 *               priceUsd:
 *                 type: number
 *                 description: Price in USD
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Image file (.jpg, .jpeg, .png, .webp)
 *     responses:
 *       201:
 *         description: Menu item created
 *       400:
 *         description: Invalid input
 *       401:
 *         description: Unauthorized
 */
menuItemRouter.post(
  "/v1/menu/items",
  authenticate,
  uploadOptionalSingleImage,
  (req, res, next) => {
    // Coerce priceUsd to number if present
    if (req.body.priceUsd !== undefined) {
      req.body.priceUsd = Number(req.body.priceUsd);
    }
    next();
  },
  validateBody(createMenuItemSchema),
  MenuItemController.create
);

/**
 * @openapi
 * /v1/menu/items/{menuItemId}:
 *   get:
 *     summary: Get a menu item by ID
 *     tags:
 *       - MenuItems
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: menuItemId
 *         required: true
 *         schema:
 *           type: string
 *         description: Menu item ID
 *     responses:
 *       200:
 *         description: Menu item details
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/MenuItem'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Menu item not found
 */
menuItemRouter.get(
  "/v1/menu/items/:menuItemId",
  authenticate,
  validateParams(menuItemIdParamSchema),
  MenuItemController.get
);

/**
 * @openapi
 * /v1/menu/items/{menuItemId}:
 *   patch:
 *     summary: Update a menu item
 *     tags:
 *       - MenuItems
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: menuItemId
 *         required: true
 *         schema:
 *           type: string
 *         description: Menu item ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/UpdateMenuItemInput'
 *     responses:
 *       200:
 *         description: Menu item updated
 *       400:
 *         description: Invalid input
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Menu item not found
 */
menuItemRouter.patch(
  "/v1/menu/items/:menuItemId",
  authenticate,
  validateParams(menuItemIdParamSchema),
  validateBody(updateMenuItemSchema),
  MenuItemController.update
);

/**
 * @openapi
 * /v1/menu/items/{menuItemId}:
 *   delete:
 *     summary: Delete a menu item
 *     tags:
 *       - MenuItems
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: menuItemId
 *         required: true
 *         schema:
 *           type: string
 *         description: Menu item ID
 *     responses:
 *       204:
 *         description: Menu item deleted
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Menu item not found
 */
menuItemRouter.delete(
  "/v1/menu/items/:menuItemId",
  authenticate,
  validateParams(menuItemIdParamSchema),
  MenuItemController.delete
);

export { menuItemRouter };


/**
 * @openapi
 * /v1/menu/items/{menuItemId}/with-modifiers:
 *   get:
 *     summary: Get a menu item with all its modifier groups and options
 *     description: |
 *       Retrieves a single menu item along with all attached modifier groups
 *       and their options. Useful for POS systems that need complete modifier
 *       information for an item.
 *     tags:
 *       - MenuItems
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: menuItemId
 *         required: true
 *         schema:
 *           type: string
 *         description: Menu item ID
 *     responses:
 *       200:
 *         description: Menu item with modifiers
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: string
 *                 categoryId:
 *                   type: string
 *                 name:
 *                   type: string
 *                 description:
 *                   type: string
 *                   nullable: true
 *                 priceUsd:
 *                   type: number
 *                 imageUrl:
 *                   type: string
 *                   nullable: true
 *                 isActive:
 *                   type: boolean
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *                 updatedAt:
 *                   type: string
 *                   format: date-time
 *                 modifiers:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       group:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                           name:
 *                             type: string
 *                           selectionType:
 *                             type: string
 *                             enum: [single, multiple]
 *                           createdAt:
 *                             type: string
 *                             format: date-time
 *                           updatedAt:
 *                             type: string
 *                             format: date-time
 *                       isRequired:
 *                         type: boolean
 *                       options:
 *                         type: array
 *                         items:
 *                           type: object
 *                           properties:
 *                             id:
 *                               type: string
 *                             label:
 *                               type: string
 *                             priceAdjustmentUsd:
 *                               type: number
 *                             isDefault:
 *                               type: boolean
 *                             createdAt:
 *                               type: string
 *                               format: date-time
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Menu item not found
 */
menuItemRouter.get(
  "/v1/menu/items/:menuItemId/with-modifiers",
  (req, res, next) => authMiddleware.authenticate(req, res, next),
  validateParams(menuItemIdParamSchema),
  MenuItemController.getWithModifiers
);