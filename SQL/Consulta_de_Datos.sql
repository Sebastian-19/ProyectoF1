use F1history;

-- Busco a ls pilotos con mas victorias de la historia

select
	dense_rank() over (order by count(Posicion) desc) as Ranking,
	CONCAT(Nombre, ' ', Apellido) as Piloto,
	count(Posicion) as 'Total de Victorias',
	Nacionalidad
		from Pilotos
			join Resultados
				on Pilotos.id_piloto = Resultados.id_piloto
		where Posicion = 1
		group by Nombre, Apellido, Posicion, Nacionalidad
	order by [Total de Victorias] desc
;

-- Busco la cantidad de victorias segun la nacionalidad de los pilotos 

with cte as
(
select 
	Nacionalidad,
	count(posicion) as 'Victorias'
		from Pilotos
			left join Resultados
				on Pilotos.id_piloto = Resultados.id_piloto
			where Posicion = 1
		group by Nacionalidad
)

select
	rank() over (order by Victorias desc) as Ranking,
	pilotos.Nacionalidad, 
	isnull(Victorias, 0) as Victorias
		from cte 
			right join pilotos
				on pilotos.Nacionalidad = cte.Nacionalidad
		group by Pilotos.Nacionalidad, cte.Victorias
	order by Victorias desc
;


-- Busco los promedios de tiempo de vuelta en cada carrera en 2023 y hago un ranking

select
	RANK() over (order by CAST(DATEADD(MILLISECOND, AVG(CAST(DATEDIFF(MILLISECOND, 0, [Tiempo]) AS BIGINT)), 0) AS TIME(3))) as 'Ranking',
	CAST(DATEADD(MILLISECOND, AVG(CAST(DATEDIFF(MILLISECOND, 0, [Tiempo]) AS BIGINT)), 0) AS TIME(3)) AS PromedioTiempo,
	Circuito,
	Gran_Premio,
	gp.Vuelta as 'Carrera N°'
		from Tiempo_de_vuelta
			left join gp
				on Tiempo_de_vuelta.id_carrera = gp.id_carrera
			left join Circuitos
				on gp.id_circuito = Circuitos.id_circuito
		where Año = 2023
		group by Gran_Premio, Circuito, Ubicacion, Pais, gp.Vuelta
		order by Ranking asc		
;

-- Busco los pilotos que mas veces ganaron en el mismo circuito

with cte as
(
select
	CONCAT(Nombre, ' ', Apellido) as Piloto,
	COUNT(posicion) as 'Cantidad de Victorias',
	Circuitos.Circuito,
	Gran_Premio,
	dense_rank() over (partition by circuito order by COUNT(posicion) desc) as 'Maximo ganador'
		from Clasificacion_pilotos as CP
			join Pilotos
				on CP.id_piloto = Pilotos.id_piloto
			join GP
				on CP.id_carrera = GP.id_carrera
			join Circuitos
				on gp.id_circuito = Circuitos.id_circuito
		where Posicion = 1
		group by Circuito , Nombre, Apellido, Gran_Premio
)

select
	Piloto,
	[Cantidad de victorias],
	Circuito,
	Gran_Premio
		from cte
		where [Maximo ganador] = 1
		order by [Cantidad de Victorias] desc, Circuito desc
;

---- VISTAS

-- Resultados del piloto 'Max Verstappen' en todos los Grandes Premios del 2023

create view winVerstappen2023 as 
select
	CONCAT(Nombre, ' ', Apellido) as Piloto,
	GP.Gran_Premio,
	Gp.Fecha,
	Resultados.Posicion,
	Resultados.Puntos
		from Pilotos
			join Resultados
				on Pilotos.id_piloto = Resultados.id_piloto
			join Gp
				on Resultados.id_carrera = gp.id_carrera
		where 
			CONCAT(Nombre, ' ', Apellido) = 'Max Verstappen'
			and
			gp.Año = 2023

select * from winVerstappen2023;

-- Busco las Scuderias ganadoras en cada año. (Saqué el resultado de 2024 ya que sigue en curso, y en 2007 Mclaren tuvo mayor puntaje pero fue descalificado por espionaje, dando lugar a que Ferrari sea campeon esa temporada).

create view Ganadoresxaño as 

with cte as
(
select 
	max(puntos) as puntos1,
	Año
	from Clasificacion_constructores 
		left join GP 
			on Clasificacion_constructores.id_carrera = GP.id_carrera 
	where PosicionTexto is null
	group by Año
),
cte2 as
(
select distinct
	puntos,
	Scuderia,
	año,
	Clasificacion_constructores.PosicionTexto
		from GP
			left join Clasificacion_constructores
				on gp.id_carrera = Clasificacion_constructores.id_carrera
			left join Constructores
				on Clasificacion_constructores.id_constructor = Constructores.id_constructor
		where PosicionTexto is null 
)

select 
	cte.Año,
	cte2.Scuderia,
	cte.puntos1 as Puntos
		from cte
			left join cte2
				on cte.Año = cte2.Año
		where 
			cte.puntos1 = cte2.Puntos
			and
			cte.Año != '2024'
			
			
select * from Ganadoresxaño	order by año desc;
				
