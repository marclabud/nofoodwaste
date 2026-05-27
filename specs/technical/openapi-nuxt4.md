# OpenAPI / Swagger Documentation Guide for Nuxt 4

Nuxt 4 provides built-in, first-class support for automatically generating and rendering OpenAPI (Swagger) documentation for server-side API endpoints. This integration is powered natively by Nuxt 4's underlying server engine, **Nitro**.

This document outlines how to configure, implement, and leverage the native OpenAPI features within a Nuxt 4 directory structure.

---

## 1. Directory Structure Context (Nuxt 4)

Nuxt 4 reorganizes files into a strict root convention. All API code resides explicitly within the `server/` directory, while server endpoints are mapped under `server/api/`.

```text
my-nuxt4-app/
├── app/                  # Client-side application layer
├── nuxt.config.ts        # Configuration
└── server/               # Server-side layer
    └── api/
        └── users/
            └── index.get.ts  # Target endpoint for API docs

```

---

## 2. Step-by-Step Configuration

### Step 1: Enable the Experimental Flag

To initialize OpenAPI generation, toggle the experimental flag inside `nuxt.config.ts`. Additionally, ensure you are utilizing the Nuxt 4 compatibility mode.

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  // Force Nuxt 4 directory and behavior conventions
  future: {
    compatibilityVersion: 4,
  },
  
  // Configure Nitro server behaviors
  nitro: {
    experimental: {
      openAPI: true
    }
  }
})

```

---

## 3. Implementing Route Metadata

### Step 2: Use `defineRouteMeta`

Nuxt 4 provides the compiler macro `defineRouteMeta` to declare API metadata directly inside your handler file. This keeps code and documentation co-located, reducing drift.

Create your API route and declare the payload and parameters:

```typescript
// server/api/users/index.get.ts

// 1. Declare OpenAPI specification metadata
defineRouteMeta({
  openAPI: {
    tags: ['Users'],
    summary: 'Retrieve all users',
    description: 'Fetches an array of active user records from the primary application datastore.',
    parameters: [
      {
        in: 'query',
        name: 'limit',
        required: false,
        description: 'The maximum number of user records to return',
        schema: { type: 'integer', default: 10 }
      }
    ],
    responses: {
      200: {
        description: 'A successful array response containing users',
        content: {
          'application/json': {
            schema: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'integer', example: 101 },
                  name: { type: 'string', example: 'Alex Smith' }
                }
              }
            }
          }
        }
      }
    }
  }
})

// 2. Export standard Nuxt 4 event handler logic
export default defineEventHandler((event) => {
  return [
    { id: 101, name: 'Alex Smith' },
    { id: 102, name: 'Taylor Jones' }
  ]
})

```

---

## 4. UI Rendering in Development

When running Nuxt 4 in a local development environment (`npx nuxi dev`), the underlying server engine starts generating automated endpoints dynamically.

### Exposed Development Interconnects:

* **Interactive UI (Scalar):** `http://localhost:3000/_scalar` *(Nuxt 4's default interactive rendering client)*
* **Interactive UI (Swagger):** `http://localhost:3000/_swagger`
* **Raw Schema Asset:** `http://localhost:3000/_openapi.json`

> ⚠️ **Production Security Notice:** By default, these UI playgrounds are disabled in production runtime builds to protect sensitive structural blueprints.

---

## 5. Type-Safe Validation Patterns

To prevent bloated metadata structures inside file code, combine Nuxt 4's schema runtime helper with validation systems like **Zod**.

```typescript
import { z } from 'zod'

// Define validation rules once
const QuerySchema = z.object({
  limit: z.coerce.number().default(10)
})

defineRouteMeta({
  openAPI: {
    tags: ['Users'],
    summary: 'Type-validated API endpoints'
    // Reference schema structural models cleanly here
  }
})

export default defineEventHandler(async (event) => {
  // Safe validation step matching the documented configuration
  const query = await getValidatedQuery(event, QuerySchema.parse)
  
  return { 
    success: true, 
    limitRequested: query.limit 
  }
})

```

```

```