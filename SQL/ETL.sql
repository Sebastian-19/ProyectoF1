create database F1history
use F1history

------------------------------------------------------------------ TABLA CIRCUITOS
select * from Circuitos;

-- elimino columnas que no son de utilidad

alter table circuitos
	drop column CircuitoRef, [URL];

-- cambio el tipo de datos

alter table circuitos
	alter column id_circuito int NOT NULL;

-- elimino las comillas en distintas columnas

update Circuitos
	set 
		Circuito = REPLACE(Circuito, '"', ''),
		Ubicacion = REPLACE(ubicacion, '"', ''),
		Pais = REPLACE(pais, '"', '')
;

-- Cambio el tipo de de datos
alter table circuitos
	alter column lat float;
alter table circuitos
	alter column long float;

-- Cambio de registros 'United States' a 'USA'

update Circuitos set Pais = REPLACE(pais, 'United States', 'USA') where Pais = 'United States';

-- La columna Circuitos.Pais tiene datos en ingles:
---- Inserto el archivo 'Traduccion_Paises.csv' que contiene los datos traducidos, la tabla se llama 'dbo.Paises'

-- Creo una nueva columna donde inserto los datos que corresponden de la tabla nueva (Nacionalidad_constructores)

alter table circuitos
	add pais1 nvarchar(50);

update Circuitos set Pais1 = español from traduccion_paises right join Circuitos on Circuitos.Pais = traduccion_paises.Ingles;

--Elimino la columna antigua y cambio el nombre de la nueva

alter table circuitos
	drop column pais;

exec sp_rename 'Circuitos.Pais1', 'Pais';

alter table circuitos
	alter column Pais nvarchar(50) NOT NULL;

------------------------------------------------------------------ TABLA CLASIFICACION

select * from Clasificacion

-- Los datos que tienen comillas son los tiempos, por eso busco aquellos datos que no tienen comillas

select distinct(q3) as 'distintosde"' from Clasificacion
	where q3 not like '%"%';

-- Los registros que no tienen comillas los convierto en NULL

update Clasificacion set q1 = NULL where q1 not like '%"%';
update Clasificacion set q2 = NULL where q2 not like '%"%';
update Clasificacion set q3 = NULL where q3 not like '%"%';

-- elimino las comillas

update Clasificacion set q1 = replace(q1, '"', '');
update Clasificacion set q2 = replace(q2, '"', '');
update Clasificacion set q3 = replace(q3, '"', '');

-- Normalizo las columnas para cambiar el data type a TIME, agrego '00:0' (solo en los casos que no esté en blanco)

update Clasificacion set q1 = CONCAT('00:0' , q1) where q1 != '';
update Clasificacion set q2 = CONCAT('00:0' , q2) where q2 != '';
update Clasificacion set q3 = CONCAT('00:0' , q3) where q3 != '';

-- Cambio el tipo de datos de las columnas

alter table clasificacion
	alter column id_clasificacion int not null;
alter table clasificacion
	alter column id_carrera int not null;
alter table clasificacion
	alter column [id_piloto] smallint not null;
alter table clasificacion
	alter column [id_constructor] smallint not null;
alter table clasificacion
	alter column [NumPiloto] tinyint NOT NULL;
alter table clasificacion
	alter column [Posicion] tinyint NOT NULL;
alter table clasificacion
	alter column q1 time(3);
alter table clasificacion
	alter column q2 time(3);
alter table clasificacion
	alter column q3 time(3);

-- los datos '00:00:00.000' los convierto en NULL
update Clasificacion set q1 = null where q1 = '00:00:00.000';
update Clasificacion set q2 = null where q2 = '00:00:00.000';
update Clasificacion set q3 = null where q3 = '00:00:00.000';

update clasificacion set q1 = '00:16:42.640' where q1 = '00:016:42.640' 



------------------------------------------------------------------ TABLA CLASIFICACION_CONSTRUCTORES

select * from Clasificacion_constructores

-- saco las comillas en la columna [PosicionTexto]

update Clasificacion_constructores set PosicionTexto = REPLACE(posiciontexto, '"', '') where PosicionTexto like '%"%';


--	Encuentro que en la columna [PosicionTexto] se repiten los datos de la columna [Posicion] exceptuando algunas columnas que tienen la letra "E", 
--	para encontrarlo use la siguiente sentencia:

select distinct (posiciontexto) as distintos from clasificacion_constructores;

--	Busco todos los registros en donde se cumpla la condicion posiciontexto = 'e'

select * from Clasificacion_constructores where posiciontexto = 'e';

--	 Para seguir con el analisis utilicé la siguiente sentencia para encontrar el año en el que sucedieron estos GP e investigar el por qué de la incoherencia de estos datos.

select 
	[id_constructor],
	[Puntos],
	Posicion,
	PosicionTexto,
	gp.[Gran_Premio],
	gp.año
		from Clasificacion_constructores
		join gp
		on clasificacion_constructores.id_carrera = gp.id_carrera
			where Clasificacion_constructores.PosicionTexto = 'E'
;

-- Busco los datos que no sean iguales entre [Posicion] y [PosicionTexto]

select
	*
		from Clasificacion_constructores
		where Posicion != PosicionTexto
			and PosicionTexto != 'e'
; -- no hay ninguno

/*	Los datos corresponden al año 2007. Investigando la temporada del 2007 sabemos que le quitaron todos los puntos de la temporada al equipo de Mclaren
	por un caso de espionaje a la Scuderia Ferrari.	
		-- Por eso, vamos a eliminar todos aquellos datos que no sean 'e' ya que son los mismos que estan en la columna [Posicion] y vamos a
		convertir los datos 'e' a 'Descalificado' 
*/
	
update Clasificacion_constructores set PosicionTexto = case 
															when posiciontexto != 'e' then null 
															when PosicionTexto = 'e' then 'Descalificado'
														end
;

-- cambio el tipo de datos

alter table clasificacion_constructores
	alter column id_clasificacionconstructores int NOT NULL;
alter table clasificacion_constructores
	alter column id_carrera int NOT NULL;
alter table clasificacion_constructores
	alter column id_constructor smallint NOT NULL;
alter table clasificacion_constructores
	alter column Puntos decimal (4,1) NOT NULL;
alter table clasificacion_constructores
	alter column Posicion tinyint NOT NULL;
alter table clasificacion_constructores
	alter column Posiciontexto varchar(15) NULL;
alter table clasificacion_constructores
	alter column Victorias tinyint NOT NULL;

	
------------------------------------------------------------------ TABLA CLASIFICACION_PILOTOS

select * from Clasificacion_pilotos;

alter table Clasificacion_pilotos
	alter column id_clasificacionpilotos int NOT NULL;
alter table Clasificacion_pilotos
	alter column id_carrera int NOT NULL;
alter table Clasificacion_pilotos
	alter column id_piloto smallint NOT NULL;
alter table Clasificacion_pilotos
	alter column Puntos decimal (4,1) NOT NULL;
alter table Clasificacion_pilotos
	alter column Posicion tinyint NOT NULL;
alter table Clasificacion_pilotos
	alter column Victorias tinyint NOT NULL;

-- Borramos las comillas de la columna [PosicionInfo]

Update Clasificacion_pilotos set PosicionInfo = REPLACE(PosicionInfo, '"', '');

-- Buscamos datos que no correspondan

select distinct (PosicionInfo) as distintos from Clasificacion_pilotos order by PosicionInfo desc;

-- Encontramos la letra "D", hacemos una consulta para investigar que piloto es y en enlace que lleva al GP en especifico.

select 
	[PosicionInfo],
	gp.url as gpurl,
	CONCAT(pilotos.nombre, ' ', Pilotos.Apellido) as Nombre_completo
		from Clasificacion_pilotos 
			join GP
				on Clasificacion_pilotos.id_carrera = gp.id_carrera
			join Pilotos
				on Clasificacion_pilotos.id_piloto = Pilotos.id_piloto
		where PosicionInfo = 'D'
;

-- Luego de investigar, la "D" refiere a la descalificacion de Schumacher en el GP de la UE en 1997.
/*	Como la columna [PosicionInfo] no tiene otra funcion distinta que la de mostrar alguna descalificacion, eliminaremos todos los registros que son repetidos de la columna
	[Posicion] exceptuando la letra "D" que pasará a llamarse "Descalificacion". 
*/ 

-- Busco los datos que no sean iguales entre [Posicion] y [PosicionInfo]

select
	*
		from Clasificacion_pilotos
		where Posicion != PosicionInfo
			and PosicionInfo != 'd'
; -- no hay ninguno

-- Cambio el tipo de datos para la columna [PosicionInfo] 

alter table Clasificacion_pilotos
	alter column PosicionInfo varchar(15) NULL;

update Clasificacion_pilotos set posicionInfo = 'Descalificado' where PosicionInfo = 'D';

update Clasificacion_pilotos set posicionInfo = null where PosicionInfo != 'Descalificado';

-- Me aseguro de que hayan quedado bien los cambios

select * from Clasificacion_pilotos where PosicionInfo = 'Descalificado';


------------------------------------------------------------------ TABLA CONSTRUCTORES

select * from Constructores

-- Elimino la columnas que no tienen utilidad

alter table Constructores
	drop column [url], [ConstructorRef];

-- Cambio los tipo de datos

alter table Constructores
	alter column id_constructor smallint NOT NULL
alter table Constructores
	alter column Scuderia varchar(50) NOT NULL
alter table Constructores
	alter column Nacionalidad varchar (50) NOT NULL
;

-- La columna Constructores.Nacionalidad tiene datos en ingles:
---- Inserto el archivo Traduccion_NacConstructores.csv que contiene los datos traducidos, la tabla se llama dbo.Nacionalidad_constructores

-- Creo una nueva columna donde inserto los datos que corresponden de la tabla nueva (Nacionalidad_constructores)

alter table constructores
	add n1 nvarchar(50) null;

update Constructores set n1 = español from Constructores
										left join Nacionalidad_constructores
											on Nacionalidad = Nacionalidad_constructores.Ingles
;

-- Elimino la columna antigua [Nacionalidad] y cambio el nombre de la nueva, de [n1] a [Nacionalidad]

alter table constructores
	drop column nacionalidad;

exec sp_rename 'Constructores.n1', 'Nacionalidad';

------------------------------------------------------------------ TABLA ESTADO

select * from Estado 

-- Cambio los tipos de datos

alter table Estado
	alter column id_estado tinyint NOT NULL;

-- La columna estado.estado tiene datos en ingles:
---- Inserto el archivo Traduccion_estado.csv que contiene los datos traducidos, la tabla se llama dbo.e1 

-- Creo una nueva columna donde inserto los datos que corresponden de la tabla nueva (e1)

alter table estado
	add Estados nvarchar(50);

-- Ingreso los datos traducidos

update Estado set estados = español from e1 right join Estado on estado.estado = e1.ingles;

-- Elimino la columna antigua [estado]. A la columna nueva [estados] la renombro a [estado]. Elimino tambien la tabla e1

alter table Estado
	drop column estado;

exec sp_rename 'Estado.Estados', 'Estado';

------------------------------------------------------------------ TABLA GP

select * from GP;

alter table GP
	alter column id_carrera int NOT NULL;

-- elimino las columnas que no son utiles (datos referidos a la practicas libres, Horarios y fechas de las clasificaciones y las carreras Sprint)

alter table GP
	drop column [quali_fecha], [quali_hora], [sprint_fecha], [sprint_hora], [url], [fp1_fecha], [fp1_hora], [fp2_fecha], [fp2_hora], [fp3_fecha], [fp3_hora];

-- Cambio tipo de datos

alter table GP
	alter column Nombre varchar (50);
alter table GP
	alter column id_circuito int NOT NULL;

-- para convertir la columna de [Hora] nvarchar(50) a tipo date, tengo que cambiar algunos registros

update GP set Hora = null where Hora = '\N';
update gp set Nombre = REPLACE(Nombre, '"', '');
update gp set Fecha = REPLACE(Fecha, '"', '');
update gp set Hora = REPLACE(Hora, '"', '');

alter table GP
	alter column Hora time(0);

-- La columna gp.Nombre tiene datos en ingles:
---- Inserto el archivo Traduccion_Gp.csv que contiene los datos traducidos, la tabla se llama dbo.gpespañol 

-- Creo una nueva columna donde inserto los datos que corresponden de la tabla nueva (gpespañol)

alter table GP
	add Nombrees nvarchar(50);

update GP set Nombrees = español from gpespañol right join GP on gpespañol.ingles = gp.Nombre;

-- Elimino la columna antigua [Nombre] y la tabla 'Gpespañol'. A la columna nueva [Nombrees] la renombro como [Gran_Premio]

alter table gp
	drop column Nombre;

exec sp_rename 'gp.Nombrees', 'Gran_Premio';

------------------------------------------------------------------ Parada_en_boxes

select * from Parada_en_boxes 
-- Elimino las comillas
update Parada_en_boxes set Hora = REPLACE(Hora, '"', '');
update Parada_en_boxes set Duracion = REPLACE(Duracion, '"', '');

-- Cambio el tipo de datos

alter table parada_en_boxes
	alter column id_carrera int NOT NULL;
alter table parada_en_boxes
	alter column id_piloto smallint NOT NULL;
alter table parada_en_boxes
	alter column Hora time (0);

-- Creo una columna llamada [duracion2] donde voy a ingresar los cambios de la columna [duracion]. Esto es por si llego a cometer algun error

alter table parada_en_boxes
	add duracion2 time (3);

-- Antes de insertar los datos a la columna [duracion2], tengo que asegurarme que datos debo cambiar:

select
	LEN(duracion) as cantidad
		from Parada_en_boxes
		group by LEN(duracion)
;

/* tenemos cantidad de caracteres:
	- 6: 00,000
	- 8: 0:00,000
	- 9: 00:00,000
*/

-- Teniendo esta informacion, se la cantidad de caracteres que tengo que agregar en la columna [duracion2]

update Parada_en_boxes
	set 
		Duracion2 = case 
						when len(Duracion) = 6 then '00:00:' + duracion
						when LEN(Duracion) = 8 then '00:0' + Duracion
						when LEN(Duracion) = 9 then '00:' + Duracion
					end
;

-- Elimino la columna [duracion] y [milisegundos]

alter table parada_en_boxes
	drop column duracion, milisegundos;

-- Cambio el nombre de la columna [duracion2] a [Duracion]

exec sp_rename 'Parada_en_boxes.duracion2', 'Duracion';

------------------------------------------------------------------ Pilotos

select * from Pilotos;

-- Elimino columnas
	
alter table Pilotos
	drop column [Pilotoref], [url]
;

-- Le agregamos codigo a los pilotos que no lo tienen en una nueva columna

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

	-- Con esta consulta puedo agregar las iniciales luego de cada espacio en blanco (cuando son 2 espacios en blanco)

	select 
		Codigo, 
		Apellido, 
		UPPER(
			concat(
				substring(Apellido, 1, 1), 
				substring(Apellido, charindex(' ', apellido) + 1 , 1),
				substring(Apellido, charindex(' ', Apellido, charindex(' ', apellido) + 1) + 1, 1)
			)
		) as codigofinal
			from Pilotos
				where LEN(Apellido) - LEN(REPLACE(Apellido, ' ', '')) = 2
	;

	/* Con esta consulta creo una columna llamada [codigofinal] donde inserto las primeras dos letras + la letra siguiente del espacio en blanco. 
		Todo esto se lo aplico a los apellidos que tengan un espacio en blanco en el tercer o cuarto caracter */

	select
		Codigo,
		Apellido,
		UPPER(
			concat(
				substring(Apellido, 1, 2), 
				substring(Apellido, charindex(' ', apellido) + 1 , 1)
			)
		) as codigofinal
			from pilotos
				where 
					LEN(Apellido) - LEN(REPLACE(Apellido, ' ', '')) = 1
					and
					(SUBSTRING(Apellido, 3, 1) = ' ' or SUBSTRING(Apellido, 4, 1) = ' ')
	;


	-- El siguiente update es para agregar los codigos segun si tienen : 2 espacios en blanco, 1 espacio en blanco en el tercer o cuarto caracter. Si no cumple ninguna de las anteriores toma los 3 primeros caracteres:

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
											substring(Apellido, charindex(' ', apellido) + 1 , 1)
										)
									)
								when codigo ='\N' then upper(left((apellido), 3))
								else
								Codigo
							end
	;

	select * from Pilotos;

	-- Borro la columna [codigo]

	alter table Pilotos
		drop column Codigo;

	-- Le cambio el nombre a la columna nueva de codigos, de [C1] a [Codigo]

	exec sp_rename 'Pilotos.C1', 'Codigo';

-- Normalizo la columna [numero] para poder convertirla en data type tinyint

alter table pilotos
	alter column numero varchar(50) null;

update Pilotos set Numero = null where Numero = '\N';

alter table Pilotos
	alter column Numero tinyint;

-- Cambio los tipos de datos
alter table Pilotos
	alter column id_piloto smallint NOT NULL;
alter table Pilotos
	alter column Nombre varchar(50) NOT NULL;
alter table Pilotos
	alter column Apellido varchar(50) NOT NULL;
Alter table Pilotos
	alter column Nacionalidad varchar(50);

-- La columna Pilotos.Nacionalidad tiene datos en ingles:
---- Inserto el archivo 'Traducciones_NacPilotos.csv' que contiene los datos traducidos, la tabla se llama dbo.PilotosNac 
-- Creo una nueva columna donde inserto los datos que corresponden de la tabla nueva (PilotosNac)

alter table pilotos
	add n1 nvarchar(50);

update Pilotos set n1 = Español from PilotosNac right join Pilotos on Pilotos.Nacionalidad = PilotosNac.Ingles;

-- Elimino la columna antigua [Nacionalidad]. Tambien cambio el nombre de la columna nueva de [n1] a [Nacionalidad]

Alter table pilotos
	drop column Nacionalidad;

exec sp_rename 'Pilotos.n1', 'Nacionalidad';

------------------------------------------------------------------ Resultados

select * from Resultados

-- Eliminamos la columnas que no son de utilidad

alter table Resultados
	drop column Milisegundos, Posicion_texto;

-- Cambio los tipos de datos

alter table Resultados
	alter column id_resultados int NOT NULL;
alter table Resultados
	alter column id_carrera int NOT NULL;
alter table Resultados
	alter column id_piloto smallint NOT NULL;
alter table Resultados
	alter column id_constructor smallint NOT NULL;
alter table Resultados
	alter column Grid tinyint NOT NULL;
alter table Resultados
	alter column posicion_orden tinyint NOT NULL;
alter table Resultados
	alter column puntos decimal(3,1) NOT NULL;
alter table Resultados
	alter column Vueltas tinyint NOT NULL;
alter table Resultados
	alter column id_estado tinyint NOT NULL;


-- Normalizo la columna [numero] para cambiar el data type a tinyint

update Resultados set numero = NULL where numero = '\N';

alter table Resultados
	alter column Numero tinyint NULL;

-- Normalizo la columna [Posicion] para cambiar el data type a tinyint

update Resultados set Posicion = NULL where Posicion = '\N';

alter table Resultados
	alter column Posicion tinyint  NULL;

-- Elimino la columna [tiempo] y creo una nueva con los datos correspondientes, llamada [t1] que voy a cambiar a [tiempo]

	alter table resultados
		add T1 varchar(50) null;

	update Resultados set T1 = case	
									when Tiempo = '\N' then null
									else
									Tiempo
								end
	;

	alter table Resultados
		drop column tiempo;

	-- Ahora busco el maximo de caracateres para poner un limite de varchar() y cambio en nombre de la columna de [t1] a [Tiempo]					

	select max(len(t1)) as 'Caracteres maximos' from Resultados; -- 11 caracteres maximo

	alter table Resultados
		alter column t1 varchar(11) null;

	exec sp_rename 'Resultados.T1', 'Tiempo';

-- Normalizo la columna [Rank] 
select * from Resultados

update Resultados set [rank] = null where [rank] = '\N'; 

alter table Resultados
	alter column [rank] tinyint NULL;

-- Repito el mismo proceso con la columna [VueltaRapida]

update Resultados set [VueltaRapida] = null where [VueltaRapida] = '\N'; 

alter table Resultados
	alter column [VueltaRapida] tinyint NULL;

-- Actualizaciones en la columna [VueltaRapida_Tiempo] para convertirla en time(3)

update Resultados set VueltaRapida_Tiempo = null where VueltaRapida_Tiempo = '\N'
												
;

select distinct(len(vueltarapida_tiempo)) from Resultados;

-- Como el unico largo de caracteres es 8 entonces tengo que agregar '00:0'

update resultados set VueltaRapida_Tiempo = '00:0' + VueltaRapida_Tiempo where VueltaRapida_Tiempo is not null;

alter table Resultados
	alter column vueltarapida_tiempo time(3) NULL;

-- Repito el mismo proceso en la columna [vueltarapida_velocidad] pero en vez de time(3) es decimal (6,3)

update Resultados set vueltarapida_velocidad = null where vueltarapida_velocidad = '\N';

alter table Resultados
	alter column vueltarapida_velocidad decimal(6,3) NULL;

------------------------------------------------------------------ Resultados_constructores

select * from Resultados_constructores;

-- Cambio los tipos de datos
alter table Resultados_constructores
	alter column id_constructoresresult smallint NOT NULL;
alter table Resultados_constructores
	alter column id_carrera int not null;
alter table Resultados_constructores
	alter column id_constructor smallint not null;
alter table Resultados_constructores
	alter column puntos decimal(3,1) not null;

-- En el caso de la columna [estado] encontramos que hay dos tipos de datos: 'D' y '\N'. La D es por la descalificacion que sufrio Mclaren en la temporada 2007 por espionaje.
-- Entonces actualizaremos los registros, cambiando de '\N' a NULL y de 'D' a 'Descalificado'.

alter table Resultados_constructores
	alter column estado varchar (20) null;

-- '\N' a NULL.
update Resultados_constructores set estado = null where Estado = '\N';

-- '"D"' a 'Descalificado'.
update resultados_constructores set estado = 'Descalificado' where estado = '"D"';

------------------------------------------------------------------ Resultados_Sprint

select * from Resultados_Sprint;

-- Eliminamos la columna [posicion_texto] y [Milisegundos] ya que no proporciona ningun dato valioso.

alter table resultados_sprint
	drop column Milisegundos, posicion_texto;

alter table resultados_sprint
	alter column id_resultados smallint NOT NULL;
alter table resultados_sprint
	alter column id_carrera int NOT NULL;
alter table resultados_sprint
	alter column id_piloto smallint NOT NULL;
alter table resultados_sprint
	alter column id_constructor smallint NOT NULL;
alter table resultados_sprint
	alter column Numero tinyint null;
alter table resultados_sprint
	alter column Grid tinyint NOT NULL
alter table resultados_sprint
	alter column Posicion varchar (2) NOT NULL
alter table resultados_sprint
	alter column Posicion_orden tinyint NOT NULL
alter table resultados_sprint
	alter column Puntos tinyint NOT NULL
alter table resultados_sprint
	alter column Vueltas tinyint NOT NULL
alter table resultados_sprint
	alter column tiempo varchar(10) NULL
alter table resultados_sprint--
	alter column vueltarapida tinyint NULL
alter table resultados_sprint
	alter column vueltarapidatiempo varchar(50) null
alter table resultados_sprint
	alter column id_estado tinyint NOT NULL
;

-- Elimino los datos '\N'

update Resultados_Sprint set Tiempo = null where Tiempo = '\N';
update Resultados_Sprint set VueltaRapida = null where VueltaRapida = '\N';
update Resultados_Sprint set VueltaRapidaTiempo = null where VueltaRapidaTiempo= '\N';

-- Consulto la cantidad de caracteres en la columna [vueltarapidatiempo] 

select
	distinct(LEN(vueltarapidatiempo)) as 'Cantidad de caracteres'
		from Resultados_Sprint;

-- El resultado es datos NULL u 8 caracteres. Entonces, cuando tengan 8 caracteres le voy a añadir '00:0'

update Resultados_Sprint set VueltaRapidaTiempo = '00:0' + VueltaRapidaTiempo where VueltaRapidaTiempo is not null;
	
-- luego de las transformaciones de los registros, podemos modificar el tipo de datos de la columna a time(3)

alter table resultados_sprint
	alter column vueltarapidatiempo time(3) null;

------------------------------------------------------------------ Tiempo_de_vuelta

select * from Tiempo_de_vuelta

-- Elimino la columna [miisegundos] ya que no me es de utilidad

alter table Tiempo_de_vuelta
	drop column milisegundos;

-- Cambio los tipos de datos

alter table Tiempo_de_vuelta
	alter column id_carrera int NOT NULL;
alter table Tiempo_de_vuelta
	alter column id_piloto smallint NOT NULL;
alter table Tiempo_de_vuelta
	alter column vuelta tinyint NOT NULL;
alter table Tiempo_de_vuelta
	alter column Posicion tinyint NOT NULL;

-- Utilizamos esta consulta para saber las diferentes cantidades de caracteres en la columna [tiempo]

	select 
		distinct(LEN(tiempo)) as 'Cantidad de caracteres'
			from Tiempo_de_vuelta;
			
	/* Obtenemos que hay de diferentes cantidades:
			.de 8:     0:00,000
			.de 9:    00:00,000
			.de 11: 0:00:00,000
		Por eso, vamos a agregar todas los nuevos registros con formato de hora a otra columna
	*/

	-- Creo la nueva columna donde voy a agregar los registros de manera correcta para que sean de tipo de dato time(3)
	alter table Tiempo_de_vuelta
		add t1 time(3) NULL;

	-- Añado la cantidad de caracteres segun sea necesario:
	update Tiempo_de_vuelta set t1 = case
										when len(Tiempo) = 8 then '00:0' + Tiempo
										when LEN(Tiempo) = 9 then '00:' + Tiempo
										when LEN(Tiempo) = 11 then '0' + Tiempo
									end
	;

	-- Confirmo que haya 12 caracteres en todos los registros
	select distinct(len(t1)) as 'Cantidad de caracteres' from Tiempo_de_vuelta;

	-- elimino la columna vieja ([Tiempo]) y cambio el nombre de la columna nueva de [t1] a [Tiempo]

	alter table Tiempo_de_vuelta
		drop column tiempo;

	exec sp_rename 'Tiempo_de_vuelta.t1', 'Tiempo';
	
	-- No admitir NULOS en la columna [tiempo]
	alter table Tiempo_de_vuelta
		alter column Tiempo time(3) NOT NULL;


-- creo las llaves primarias de todas las tablas

	alter table Circuitos
		add constraint PKcircuito primary key ([id_circuito]);
	alter table Clasificacion
		add constraint PKclasificacion primary key ([id_clasificacion]);
	alter table Clasificacion_constructores
		add constraint PKclas_constructores primary key ([id_clasificacionconstructores]);
	alter table Clasificacion_Pilotos
		add constraint PKclas_pilotos primary key ([id_clasificacionpilotos]);
	alter table Constructores
		add constraint PKconstructor primary key ([id_constructor]);
	alter table Estado
		add constraint PKestado primary key ([id_estado]);
	alter table GP
		add constraint PKgp primary key ([id_carrera]);
	alter table Pilotos
		add constraint PKpiloto primary key ([id_piloto]);
	alter table resultados
		add constraint PKresultados primary key ([id_resultados]);
	alter table Resultados_Constructores
		add constraint PKresul_constructores primary key ([id_constructoresresult]);
	alter table Resultados_sprint
		add constraint PKresul_sprint primary key ([id_resultados]);
	

-- Creo las llaves foraneas 

	alter table Clasificacion
		add constraint FKgp	foreign key (id_carrera) references gp(id_carrera);
	alter table Clasificacion
		add constraint FKpiloto foreign key (id_piloto) references pilotos(id_piloto);
	alter table Clasificacion
		add constraint FKconstructor foreign key (id_constructor) references Constructores(id_constructor);

	alter table clasificacion_constructores
		add constraint FKgp1 foreign key (id_carrera) references gp(id_carrera);
	alter table clasificacion_constructores
		add constraint FKconstructor1 foreign key (id_constructor) references constructores(id_constructor);

	alter table clasificacion_pilotos
		add constraint FKgp2 foreign key (id_carrera) references gp(id_carrera);
	alter table clasificacion_pilotos
		add constraint FKpiloto1 foreign key (id_piloto) references pilotos(id_piloto);

	alter table gp
		add constraint FKcircuito foreign key (id_circuito) references circuitos(id_circuito);

	alter table Parada_en_boxes
		add constraint FKgp3 foreign key (id_carrera) references gp(id_carrera);
	alter table Parada_en_boxes
		add constraint FKpiloto2 foreign key (id_piloto) references pilotos(id_piloto);

	alter table Resultados
		add constraint FKgp4 foreign key (id_carrera) references gp(id_carrera);
	alter table Resultados
		add constraint FKpiloto3 foreign key ([id_piloto]) references pilotos([id_piloto]);
	alter table Resultados
		add constraint FKconstructor2 foreign key ([id_constructor]) references constructores([id_constructor]);
	alter table Resultados
		add constraint FKestado foreign key ([id_estado]) references Estado([id_estado]);

	alter table resultados_constructores
		add constraint FKgp5 foreign key ([id_carrera]) references gp([id_carrera]);
	alter table resultados_constructores
		add constraint FKconstructor3 foreign key ([id_constructor]) references Constructores([id_constructor]);

	alter table Resultados_Sprint
		add constraint FKgp6 foreign key (id_carrera) references gp(id_carrera);
	alter table Resultados_Sprint
		add constraint FKpiloto4 foreign key ([id_piloto]) references pilotos([id_piloto]);
	alter table Resultados_Sprint
		add constraint FKconstructor4 foreign key ([id_constructor]) references constructores([id_constructor]);
	alter table Resultados_Sprint
		add constraint FKestado1 foreign key ([id_estado]) references Estado([id_estado]);

	alter table Tiempo_de_vuelta
		add constraint FKgp7 foreign key ([id_carrera]) references gp([id_carrera]);
	alter table Tiempo_de_vuelta
		add constraint FKpiloto5 foreign key ([id_piloto]) references pilotos([id_piloto]);


-- Final del ETL :)