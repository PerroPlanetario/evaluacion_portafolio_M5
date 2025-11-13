el modelo E-R se hizo basado en lo que la tarea pedia sin modificaciones
pero al ir escribiendo el script fui modificando cosas para que el script
no solo cumpliera en el contexto de la tarea sino que estuviera pensado para su
uso real, el script terminado aun no tiene usabilidad real necesita pulirse sin
embargo me parece un script apropiado para entrega y aunque no se cumple con algunos
requerimientos como el eliminado de datos "fisicos" si se aplica un eliminado de datos
"logico"al poder cambiar los productos y proveedores a inactivo(activo=0) dejandolos
no utilizables por el sistema pero manteniendolos para no perder datos historicos(de todos modos
se pueden eliminar productos y proveedores que jamas hayan participado en una transaccion sin problemas
pero me parecio que no tenia mucho sentido)
cosa que me parece util pues nos hemos encontrado buscando el contacto de proveedores descartados
que luego de años se decide volver a cotizar con ellos o cosas por el estilo.
si bien los datos que se utilizaron no son reales si son una aproximanción.

el funcionamiento del script esta descrito con comentarios en el mismo script y este README esta mas pensado en explicar 
brevemente por que se construyo de esa manera.

hay algunas querys extras que use para ir probando el correcto funcionamiento del Script, las deje por que considere que no
afectan, sino que al contrario le suman a la entrega.

 **me comentó gente que trábaja en bases de datos que el hecho de poner el precio
historico en la transacción permitiria "chanchullos" como que la transaccion se ingrese 
con precio 1 para comprar, de todos modos los "chanchullos" quedarian registrados y el script
esta pensado para la tarea y aun no como un script para utilizar "en el mundo real"
ademas me informaron que  con muchos años de experiencia en base de datos que no han visto necesidad en desnormalizar por lo que la ventaja
que coloque basada en la información recopilada de paginas educativas y me imagino que solo aplica para bases de datos monstruosamente grandes.