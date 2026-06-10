FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build-only

FROM node:22-alpine
RUN npm i -g serve
WORKDIR /app
COPY --from=build /app/dist .
EXPOSE 3001
CMD ["serve", "-s", ".", "-l", "3001"]
