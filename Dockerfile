# Stage 1: Build stage
FROM node:20-alpine AS builder

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias (solo producción y desarrollo para build)
RUN npm ci

# Copiar código fuente
COPY . .

# Compilar la aplicación
RUN npm run build

# Stage 2: Production stage
FROM node:20-alpine AS production

# Establecer directorio de trabajo
WORKDIR /app

# Crear usuario no root para seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar solo dependencias de producción
RUN npm ci --only=production && \
    npm cache clean --force

# Copiar archivos compilados desde el stage de build
COPY --from=builder /app/dist ./dist

# Cambiar propietario de los archivos
RUN chown -R nestjs:nodejs /app

# Cambiar a usuario no root
USER nestjs

# Exponer puerto
EXPOSE 4000

# Variable de entorno para el puerto
ENV PORT=4000
ENV NODE_ENV=production

# Comando para iniciar la aplicación
CMD ["node", "dist/main.js"]

