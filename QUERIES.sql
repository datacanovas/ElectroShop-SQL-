use electroshop;

# ¿Cuál es el ingreso total generado por cada categoría de producto en todas las tiendas durante 2024?

select p.categoría,sum(v.total_venta) as ingreso_total
from ventas v 
join producto p on v.producto_id=p.producto_id
join fecha f on v.fecha_id=f.fecha_id
where f.año=YEAR(CURDATE()) 
group by p.categoría
order by ingreso_total DESC;

# ¿Qué clientes han gastado más de $1000 en el mes de marzo de este año y que productos compraron?

SELECT 
    c.nombre_cliente,
    c.correo,
    SUM(v.total_venta) AS total_gastado,
    GROUP_CONCAT(DISTINCT p.nombre_producto) AS productos_comprados
FROM 
    Ventas v
JOIN 
    Cliente c ON v.cliente_id = c.cliente_id
JOIN 
    Producto p ON v.producto_id = p.producto_id
JOIN 
    Fecha f ON v.fecha_id = f.fecha_id
    
where f.mes  = 3

GROUP BY 
    c.nombre_cliente, c.correo
HAVING 
    total_gastado > 1000
ORDER BY 
    total_gastado DESC;


# ¿Qué productos han sido más vendidos por cada tienda durante el trimestre de este año?
SELECT 
    t.nombre_tienda,
    p.nombre_producto,
    SUM(v.cantidad) AS cantidad_vendida
FROM 
    Ventas v
JOIN 
    Tienda t ON v.tienda_id = t.tienda_id
JOIN 
    Producto p ON v.producto_id = p.producto_id
JOIN 
    Fecha f ON v.fecha_id = f.fecha_id
WHERE 
     f.trimestre = 1
GROUP BY 
    t.nombre_tienda, p.nombre_producto
ORDER BY 
    t.nombre_tienda, cantidad_vendida DESC;


# ¿Cuáles fueron los productos menos vendidos por cada tienda durante el último mes?

select p.nombre_producto, t.nombre_tienda, count(*) as cantidad_vendida
from ventas v 
join producto p on p.producto_id=v.producto_id
join tienda t on v.tienda_id=t.tienda_id
join fecha f on v.fecha_id=f.fecha_id
where f.mes=MONTH(CURDATE())-1 and f.año=YEAR(CURDATE()) 
group by p.nombre_producto, t.nombre_tienda
ORDER BY cantidad_vendida ASC;

#Comparación del rendimiento de ventas entre días laborables y fines de semana:

SELECT 
    CASE 
        WHEN f.día_semana IN (1, 7) THEN 'Fin de semana'
        ELSE 'Día laborable'
    END AS tipo_dia,
    SUM(v.cantidad) AS total_ventas
FROM 
    Ventas v
JOIN 
    Fecha f ON v.fecha_id = f.fecha_id
WHERE 
    f.año = YEAR(CURDATE())
GROUP BY 
    tipo_dia;
    
#Cantidad de clientes nuevos registrados el mes pasado y porcentaje de ellos que realizaron una compra en su primer mes:

SELECT 
    COUNT(*) AS clientes_nuevos,
    SUM(CASE WHEN v.fecha_id = f_primer_compra THEN 1 ELSE 0 END) AS clientes_nuevos_con_compras,
    (SUM(CASE WHEN v.fecha_id = f_primer_compra THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS porcentaje_compras_primer_mes
FROM 
    Cliente c
JOIN 
    Ventas v ON c.cliente_id = v.cliente_id
JOIN 
    (SELECT 
         cliente_id,
         MIN(fecha_id) AS f_primer_compra
     FROM 
         Ventas
     GROUP BY 
         cliente_id) AS primer_compra ON c.cliente_id = primer_compra.cliente_id
JOIN 
    Fecha f ON primer_compra.f_primer_compra = f.fecha_id
WHERE 
    f.año = YEAR(CURDATE()) 
    AND f.mes = MONTH(CURDATE()) - 1;
    
    
# Tendencia de ventas de los productos de alta gama(precio>1000) durante 2024:

SELECT 
    p.nombre_producto,
    f.mes AS mes,
    f.año AS año,
    SUM(v.cantidad) AS ventas_mensuales
FROM 
    Ventas v
JOIN 
    Producto p ON v.producto_id = p.producto_id
JOIN 
    Fecha f ON v.fecha_id = f.fecha_id
WHERE 
    p.precio > 1000 AND f.año = YEAR(CURDATE()) 
GROUP BY 
    p.nombre_producto, mes,año
ORDER BY 
    año, mes;


#¿Cuál es el proveedor que ha generado más ingresos y cuantos productos diferentes suministra?

SELECT pr.nombre_proveedor, SUM(v.total_venta) AS ingresos_totales,
       COUNT(DISTINCT p.producto_id) AS productos_diferentes
FROM Proveedor pr
JOIN Producto p ON pr.proveedor_id = p.proveedor_id
JOIN Ventas v ON p.producto_id = v.producto_id
GROUP BY pr.nombre_proveedor
ORDER BY ingresos_totales DESC
LIMIT 1;

#¿Cuál es el total de ventas por trimestre y su crecimiento con respecto al trimestre anterior?
 
SELECT f.trimestre, SUM(v.total_venta) AS total_ventas,
       LAG(SUM(v.total_venta)) OVER (ORDER BY f.trimestre) AS ventas_anterior
FROM Ventas v
JOIN Fecha f ON v.fecha_id = f.fecha_id
GROUP BY f.trimestre;


#¿Cuál es la tasa de devolución
# promedio por cliente en comparación con el total de ventas realizadas por cada cliente?

SELECT
    c.cliente_id,
    c.nombre_cliente,
    (SUM(d.cantidad_devuelta) / NULLIF(SUM(v.cantidad), 0)) AS tasa_devolución_promedio
FROM
    Devoluciones d
	JOIN Cliente c ON d.cliente_id = c.cliente_id
	JOIN Ventas v ON d.cliente_id = v.cliente_id
GROUP BY
    c.cliente_id, c.nombre_cliente
ORDER BY
    tasa_devolución_promedio DESC;

#Cuál es el promedio de ventas mensuales por categoría de producto durante 2024?

SELECT
    f.año,
    f.mes,
    p.categoría,
    AVG(v.total_venta) AS promedio_ventas
FROM
    Ventas v
     JOIN Fecha f ON v.fecha_id = f.fecha_id
     JOIN Producto p ON v.producto_id = p.producto_id
WHERE
    f.año = YEAR(curdate()) 
GROUP BY
    f.año, f.mes, p.categoría
ORDER BY
    promedio_ventas DESC;

# ¿Cuál es la proporción de productos devueltos por cada categoría
# de producto en relación con las ventas totales de esa categoría durante el último año?

WITH DevolucionesPorCategoria AS (
    SELECT
        p.categoría,
        SUM(d.cantidad_devuelta) AS cantidad_devuelta_por_categoria
    FROM
        Devoluciones d
         JOIN Producto p ON d.producto_id = p.producto_id
         JOIN Fecha f ON d.fecha_id = f.fecha_id
    WHERE
        f.fecha BETWEEN DATE_ADD(CURDATE(), INTERVAL -1 YEAR) AND CURDATE() -- Último año
    GROUP BY
        p.categoría
),
VentasPorCategoria AS (
    SELECT
        p.categoría,
        SUM(v.total_venta) AS ventas_totales_por_categoria
    FROM
        Ventas v
         JOIN Producto p ON v.producto_id = p.producto_id
         JOIN Fecha f ON v.fecha_id = f.fecha_id
    WHERE
        f.fecha BETWEEN DATE_ADD(CURDATE(), INTERVAL -1 YEAR) AND CURDATE() 
    GROUP BY
        p.categoría
)
SELECT
    dpc.categoría,
    (dpc.cantidad_devuelta_por_categoria / NULLIF(vpc.ventas_totales_por_categoria, 0)) * 100 AS proporción_devoluciones_vs_ventas
FROM
    DevolucionesPorCategoria dpc
     JOIN VentasPorCategoria vpc ON dpc.categoría = vpc.categoría;










    
    








    



