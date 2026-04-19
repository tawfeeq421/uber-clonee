FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S nextjs && adduser -S nextjs -G nextjs
COPY --from=builder /app.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

RUN chowm -R nextjs:nextjs /app
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
