# PRISMA INSTALLATION

## Context
When setting up a new project that requires database ORM functionality, Prisma provides a type-safe database access layer.

## Solution
1. Install Prisma CLI globally: `npm install -g prisma`
2. Add Prisma to project: `npm install prisma --save-dev`
3. Initialize Prisma: `npx prisma init`
4. Configure schema.prisma with database connection and models
5. Generate Prisma client: `npx prisma generate`
6. Push schema to database: `npx prisma db push` (for development) or `npx prisma migrate dev` (for production-ready migrations)

## Example
```bash
# Install CLI globally
npm install -g prisma

# In project directory
npm install prisma --save-dev
npx prisma init

# Edit schema.prisma file with your database URL and models
# Then generate client
npx prisma generate

# Push to database
npx prisma db push
```

