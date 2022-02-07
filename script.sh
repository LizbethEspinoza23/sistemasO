#! /bin/bash
### De los argumentos recibidos, el primero ($1) debe ser el archivo del listado
echo -e "=====>> Script para tomar lista <<=====\n"
if [[ ! (-e $1) ]];
then
	echo " El archivo : $1 : no existe!!! " 
	exit
fi
echo " =====>> Tomando asistencia y archivando en $1"

if ! command -v "tesseract" &> /dev/null
then 
	echo "==========> Se instalara el programa: tesseract-ocr"
	sudo apt-get install tesseract-ocr
fi

if ! command -v "convert" &> /dev/null
then 
	echo "==========> Se instalara el programa: imagemagick"
	sudo apt-get install imagemagick
fi


for imagen in *.png;
do 	
	tail -n +2 $1 > .encabezado.csv
	# extraer la fecha del nombre de la imagen
	fecha=$(echo $imagen | cut -b 4-13) ;
	echo -e "\n ======> Fecha que asiste: $fecha <=======\n"
	### corta la imagen, para tener solo la lista de asistentes y se guarda en un archivo oculto .out.png
	convert "$imagen" -crop 260x880+1600+200  .out.png &> /dev/null
	### obtiene los caracteres
	tesseract .out.png data &> /dev/null
	## agrega la fecha a la primera fila del csv
	echo "$(head -1 $1),${fecha}"> .aux.csv
	while IFS= read -r line;
	do
	
		cedula=$(echo "$line" | cut -d "," -f 2 );
		## validacion de la cedula 
		if [[ $(echo "$cedula" | ./cedula.awk) -ne "1" ]];
		then
			echo -e "\n=====>> La cedula no es valida xx $cedula xx\n"
		else 

			### agregar a la lista
			if [[ $(grep "$cedula" data.txt) ]]; 
			then
				echo "$line,S" >> .aux.csv
			else
				echo "$line,N" >> .aux.csv
			fi
		fi
	done < .encabezado.csv
	cat .aux.csv > $1
	
done

#Se eliminan los archivos creados
rm .aux.csv .encabezado.csv .out.png data.txt
