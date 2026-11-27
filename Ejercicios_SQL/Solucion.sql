### Solución del taller 

---1. Muestra cinco filas de `prestamos` con las columnas `prestamo_id`, `socio_id`, `libro_id` y `fecha_prestamo`.
SELECT prestamo_id, socio_id , libro_id, fecha_prestamo
from `biblioteca.prestamos`
limit 5

--2. ¿Cuántos libros hay en el catálogo?
SELECT 
count(libro_id)
from `biblioteca.libros`

-- 3. ¿Cuántos socios están activos?
SELECT
count(socio_id)
FROM `biblioteca.socios` WHERE activo = TRUE

## Nivel 2 · Filas y personas
-- ¿Cuántos préstamos tiene «Dune»? ¿Cuántas personas distintas lo pidieron?

SELECT
  count(socio_id)
FROM `biblioteca.prestamos` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
where B.titulo = "Dune"

SELECT
  count(distinct(socio_id))
FROM `biblioteca.prestamos` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
where B.titulo = "Dune"

-- Haz lo mismo para «Emma». ¿Coinciden los dos números? ¿Por qué sí o por qué no?
SELECT
  count(socio_id)
FROM `biblioteca.prestamos` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
where B.titulo = "Emma"

SELECT
  count(distinct(socio_id))
FROM `biblioteca.prestamos` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
where B.titulo = "Emma"

""" Los valores son diferentes ya que un socio puede prestar varias veces un libro """

-- ¿Cuántas filas tiene la tabla `prestamos` en total? ¿Y cuántos socios distintos aparecen en ella?
SELECT
    count(prestamo_id)
FROM `biblioteca.prestamos`

SELECT
    count(DISTINCT(socio_id))
FROM `biblioteca.prestamos`

## Nivel 3 · Indicadores y cortes
--Préstamos por libro: los cinco libros más prestados, con su título.
SELECT titulo,
  count(prestamo_id) AS total_prestamos
FROM `biblioteca.prestamos` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
GROUP BY (B.titulo)
order by total_prestamos DESC
LIMIT 5 

-- Préstamos por categoría. Necesitarás unir `prestamos` con `libros`
SELECT categoria,
  count(prestamo_id) AS total_prestamos
FROM `biblioteca.prestamos` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
GROUP BY (B.categoria)
order by total_prestamos DESC

-- Préstamos por mes.
SELECT 
  extract(month from A.fecha_prestamo) as mes,
  count(prestamo_id) AS total_prestamos
FROM `biblioteca.prestamos` AS A
GROUP BY (mes)
order by mes

-- ¿Cuántos préstamos siguen abiertos, es decir, sin fecha de devolución?
SELECT
  count(prestamo_id) AS Vacias
FROM `biblioteca.prestamos` AS A
WHERE fecha_devolucion IS NULL

## Nivel 4 · Calidad de datos (escena 3)

--En `prestamos_abril`, ¿hay filas repetidas? Encuentra los `prestamo_id` que aparecen más de una vez.
SELECT prestamo_id,
  count(*) AS Cantidad
FROM `biblioteca.prestamos-abril`
GROUP BY prestamo_id
having count(*) > 1
order by Cantidad DESC

--¿Cuántos préstamos de «Dune» hay en abril contando todas las filas? ¿Y contando cada préstamo una sola vez? Compara con el promedio mensual de enero a marzo.
SELECT
  count(prestamo_id) AS total
FROM `biblioteca.prestamos-abril` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
where B.titulo = "Dune"

SELECT
  count(DISTINCT(prestamo_id))
FROM `biblioteca.prestamos-abril` AS A
left join `biblioteca.libros` AS B ON A.libro_id = B.libro_id
where B.titulo = "Dune"

""" Para comparar usé UNION ALL"""
SELECT
  B.titulo,
  EXTRACT(MONTH FROM A.fecha_prestamo) AS mes,
  COUNT(A.prestamo_id) AS total_prestamos
FROM `biblioteca.prestamos-abril` AS A
LEFT JOIN `biblioteca.libros` AS B
  ON A.libro_id = B.libro_id
WHERE B.titulo = "Dune"
GROUP BY B.titulo, mes

UNION ALL

SELECT
  B.titulo,
  EXTRACT(MONTH FROM C.fecha_prestamo) AS mes,
  COUNT(C.prestamo_id) AS total_prestamos
FROM `biblioteca.prestamos` AS C
LEFT JOIN `biblioteca.libros` AS B
  ON C.libro_id = B.libro_id
WHERE B.titulo = "Dune"
GROUP BY B.titulo, mes

ORDER BY mes

-- Las fechas de abril llegaron como texto, en formato `dd/mm/aaaa`. Conviértelas a fecha real y cuenta los préstamos de abril por semana.

""" Al validar las columnas de fecha, estas ya son tipo DATE, por lo que no hubo necesidad de convertir en tipo fecha """
SELECT
  DATE_TRUNC(fecha_prestamo, WEEK(MONDAY)) AS inicio_semana,
  COUNT(prestamo_id) AS total_prestamos
FROM `biblioteca.prestamos-abril`
GROUP BY inicio_semana
ORDER BY inicio_semana

-- ¿Hay libros del catálogo que nunca se prestaron entre enero y marzo?
SELECT titulo,
  count(B.prestamo_id) AS total_prestamos
FROM `biblioteca.libros` AS A
LEFT JOIN `biblioteca.prestamos` AS B
  ON A.libro_id = B.libro_id
GROUP BY titulo
HAVING total_prestamos = 0
ORDER BY total_prestamos

## Desafío final
-- Escribe tres revisiones, en forma de consulta, que Lucía podría correr cada mes antes de publicar su informe, una por cada riesgo de su ficha: filas repetidas, fechas en otro formato y libros sin préstamo. Cada una debería devolver cero filas cuando todo está bien.

-- Duplicados
SELECT
  SUM(cantidad - 1) AS registros_duplicados
FROM (
  SELECT COUNT(*) AS cantidad
  FROM `biblioteca.libros`
  GROUP BY libro_id
  HAVING COUNT(*) > 1
)

SELECT libro_id, COUNT(*) AS cantidad
FROM `biblioteca.libros`
GROUP BY libro_id
HAVING COUNT(*) > 1

""" El anterior código se haría con las demás tablas pero con el prestamo_id y los socios_id, que son los datos que deberían ser únicos"""

-- Validar fechas
""" Primero se valida si hay fechas vacías """
SELECT
  COUNT(*) AS total_registros,
  COUNTIF(fecha_prestamo IS NULL) AS fechas_nulas
FROM `biblioteca.prestamos`

""" Luego validar que la fecha este en tipo DATE, se puede hacer con cada columna que tenga fechas """

SELECT
  fecha_prestamo,
  SAFE.PARSE_DATE('%d/%m/%Y', fecha_prestamo) AS fecha_convertida
FROM `biblioteca.prestamos`
WHERE SAFE.PARSE_DATE('%d/%m/%Y', fecha_prestamo) IS NULL
  AND fecha_prestamo IS NOT NULL;

-- libros sin prestamos

SELECT titulo,
  count(B.prestamo_id) AS total_prestamos
FROM `biblioteca.libros` AS A
LEFT JOIN `biblioteca.prestamos` AS B
  ON A.libro_id = B.libro_id
GROUP BY titulo
HAVING total_prestamos = 0
ORDER BY total_prestamos