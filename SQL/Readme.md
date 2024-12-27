# Procesos de ETL (Extract, Transform, Load)

## Extracción de datos
 
Los datos fueron extraídos de un dataset de la plataforma Kaggle, del siguiente link ![](https://www.kaggle.com/datasets/rohanrao/formula-1-world-championship-1950-2020).
Son 14 archivos en formato plano .csv. 
Para ejecutarlos dentro de SQL Server, primero cree una base de datos llamada “f1history” dónde importe los archivos planos a través del asistente para importación y exportación en SQL.
Luego de importar los datos a mi base de datos, continúe con la transformación de la misma.



## Transformación de datos

En este apartado se encuentran algunos procesos de transformación realizados sobre la base de datos. 

#### Estandarización:
Unifico a Estados Unidos bajo el nombre de "USA", para que no haya redundancia y se pueda hacer un análisis correcto.
```SQL
update Circuitos set Pais = 'USA' where Pais = 'United States';
```

#### Normalización:
Normalice los datos de la columna al convertir todos los registros al mismo formato "00:00:00". Con el formato correcto, puedo convertir el tipo de datos de la columna a time(3).
```sql
-- Los valores que NO tienen comillas los convierto a valores NULL.
update Clasificacion set q1 = NULL where q1 not like '%"%';
-- Elimino las comillas.
update Clasificación set q1 = replace(q1, '"', '');
-- Por ultimo, agrego los caracteres "00:0" que corresponden a las horas y minutos, solamente a los registros que no esten vacios.
update Clasificacion set q1 = CONCAT('00:0' , q1) where q1 != '' and NOT null;
```

#### Modificación estructural:
Cambio el tipo de datos de la columna.
```SQL
alter table clasificacion
	alter column q3 time(3);
```

#### Reestructuracion:
Reestructuro una tabla, reemplazando una columna integrando una columna nueva , 
En la tabla "Pilotos" hay una columna llamada [Codigo] que contiene siglas de 3 caracteres para identificar a los pilotos. Sin embargo, se encontro que no todos los pilotos tienen un codigo asignado. Por ello es que generamos los codigos faltantes con el siguiente proceso:
```sql
	-- Creo la columna termporal donde van a estar los datos nuevos
	alter table pilotos
		add C1 char(3) NULL;


	-- Consultamos la cantidad de espacios en blanco que hay en los apellidos
	select 
		LEN(Apellido) - LEN(REPLACE(Apellido, ' ', '')) as 'Espacios en blanco',
		count(*) as 'Cantidad de pilotos'
			from Pilotos
			where LEN(Apellido) - LEN(REPLACE(Apellido, ' ', '')) >= 1
			group by LEN(Apellido) - LEN(REPLACE(Apellido, ' ', ''))
	;
/* 
Encontramos 4 escenarios distintos que modifican el tipo de actualizacion que tendran los codigos, que son los siguientes:
- Dos espacios en el apellido. Utiliza las 3 letras iniciales del apellido.
- Un espacio en el apellido. Utiliza las 2 primeras letras de la primera palabra y la letra inicial de la segunda palabra.
- Sin espacios. Utiliza las 3 primeras letras.
- Codigo preexistente. Si hay un codigo en la columna original, se preserva sin cambios.
*/

update Pilotos set c1 =	case 
				when codigo ='\N' and LEN(Apellido) - LEN(REPLACE(Apellido, ' ', '')) = 2 
				then 
				  UPPER(
				    concat(
					    substring(Apellido, 1, 1), 
					    substring(Apellido, charindex(' ', apellido) + 1 , 1),
					    substring(Apellido, charindex(' ', Apellido, charindex(' ', apellido) + 1) + 1, 1)
            )
          )
        when
          codigo ='\N' 
          and LEN(Apellido) - LEN(REPLACE(Apellido, ' ', '')) = 1
          and (SUBSTRING(Apellido, 3, 1) = ' ' or SUBSTRING(Apellido, 4, 1) = ' ') 
        then 
          UPPER(
  					concat(
							substring(Apellido, 1, 2), 
							substring(Apellido, charindex(' ', apellido) + 1 , 1)							)
          )
        when codigo ='\N'
        then upper(left((apellido), 3))
        else Codigo
      end
	;

-- Borro la columna original.

alter table Pilotos
	drop column Codigo;

-- Actualizo el nombre de la columna nueva, de "C1" a "Codigo".

	exec sp_rename 'Pilotos.C1', 'Codigo';
```

#### Relaciones y claves

Creacion de llave primaria (PK):
```SQL
alter table Circuitos
		add constraint PKcircuito primary key ([id_circuito]);
```
Creacion de llave foranea (FK):
```SQL
alter table Clasificacion
	add constraint FKgp	foreign key (id_carrera) references gp(id_carrera);
```

####  Tabla temporal

Debido a que en la tabla "Resultados" las columnas referidas a las vueltas rapidas de cada piloto están incompletas, voy a obtener los datos que necesito extrayendolos de la tabla "Tiempo_de_vuelta". Especificamente, de las columnas *[Tiempo]*  y *[Vuelta]*, con el siguiente procedimiento:
```SQL
-- Primera tabla temporal para extaer los valores minimos de la columna [Tiempo], que son los registros de vueltas rapidas de cada piloto en cada carrera.
with cte as 
(
select
	MIN(Tiempo) as VueltaRapidaTiempo,
	id_carrera,
	id_piloto
		from Tiempo_de_vuelta
		group by id_carrera, id_piloto
)
, -- Segunda tabla temporal utilizada para obtener en que vuelta se realizó la vuelta rapida.
cte2 as
(
	select 
		cte.*,
		Vuelta,
		ROW_NUMBER() over (partition by VueltaRapidaTiempo, cte.id_carrera, cte.id_piloto order by VueltaRapidaTiempo) as cantidad
			from cte, Tiempo_de_vuelta
				where 
					Tiempo = VueltaRapidaTiempo
					and
					Tiempo_de_vuelta.id_carrera = cte.id_carrera
					and
					Tiempo_de_vuelta.id_piloto = cte.id_piloto
)
 /* 
Creo la tabla temporal, nombrada "TdV_temporal" compuesta por cuatro columnas:
 [id_carrera]. Indice que identifica la carrera correspondiente.
 [id_piloto]. Indice que identifica al piloto correspondiente.
 [Vuelta]. Vuelta especifica en la que se registró la vuelta rápida.
 [VueltaRapidaTiempo]. Registro del tiempo asociado a la vuelta rápida.
 */
select id_carrera, id_piloto, Vuelta, VueltaRapidaTiempo into TdV_temporal from cte2 where cantidad = 1;
```
## Carga

Luego de que la base de datos haya sido transformada, con sus relaciones definidas entre tablas y sus datos correctamente estructurados y limpios, está lista para ser utilizada. En este caso fue importada desde Power Bi para su futuro análisis y visualización.

# Consultas de datos

En la Query [Consulta_de_Datos](SQL/Consulta_de_Datos.sql), se encuentran consultas complejas realizadas a la base de datos.

Entre ellas podemos encontrar la siguiente:


- Creo una consulta para generar un ranking de las victorias de los pilotos acumuladas según su nacionalidad. Los resultados son desde el año 1950 hasta el año 2023.

```SQL

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
``` 
