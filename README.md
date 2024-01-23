# Actividad-Terraform

## Actividad 1: 
### Provisionamiento de infra web con balanceador de carga

Para poder levantar un servidor web a traves de terraform se definieron en un archivo .tf los siguientes recursos:

1.      resource "aws_default_vpc" "default"
    Con este recurso se importa la VPC creada por default en la región previamente configurada.

2.      data "aws_subnets" "subnets"
    Este elemento data importa las sub redes pertenciencies en la VPC indicada en sus atributos. Es importante que las subnets existan en el mismo VPC que se utilizara para alojar el resto de servicios.

3.      resource "aws_security_group" "ec2_security_group"
    Este recurso crea un nuevo grupo de seguridad con 2 reglas, 1 de entrada y 1 de salida. 
    - La regla de entrada define desde como y desde donde se puede acceder a una instancia, en este caso a traves del puerto 80 y desde cualquier IP 
     - La regla de la salida define a donde la instancia puede enviar información, en este caso a cualquier IP y cualquier protocolo.

4.      resource "aws_instance" "app_server"
    La instancia del servidor como tal, sera quien reciba las request enviadas a traves del balanceador de carga y regrese una respuesta. Su configuración incluye los siguientes parámetros:

    - *ami*: id de la imagén que se utilizara para montar la instancia. 

    - *instance_type*: tipo de instancia a levantar. Varian en capacidades y costo de uso.

    - *security_groups*: se debe especificar el id de el/los grupo/s de seguridad que usara la instancia. Para este caso se uso el grupo de seguridad definido previamente, sin embargo de usar otro grupo de seguridad o añadirle reglas al definido lo importante es que cuenta con al menos las reglas definidas previamente.

    - *user_data*: Este campo se usa para entregarle una lista de comando shell que ejecutara la instancia al iniciarse. En este caso de uso se especifícan los mínimos comando para abrir un servidor web cuya respuesta de un HTML que imprime Hello World por pantalla.

Por el momento con los recursos ya especifícados es suficiente para levantar una instancia EC2 como servidor web al que se puede acceder a traves de su IP pública o DNS pública. Para añadirle una capa más de seguridad y funcionalidad le añadimos un balanceador de carga con los siguientes recursos:

5.      resource "aws_lb" "test"
    Este recurso especifíca el balanceador de carga como tal con los siguientes atributos:
    - *internal*: especifíca si el balanceador de carga es de tipo interno o externo. En este caso se entrega _false_ para un balanceador de carga externo.
    - *load_balancer_type*: especifíca el tipo de balanceador de carga entre los diferentes tipos disponibles. En este caso el balanceador de carga es de tipo "application".
    - *security_groups*: al igual que a la instancia EC2 al load balancer se le debe entregar un security group que defina las reglas con las que puede interactuar con el exterior de la instancia. Para este caso de uso es importante que cuente con las reglas necesarias para poder acceder a la instancia EC2 por lo que se uso su mismo security group.
    - *subnets*: se deben entregar las subnets sobre las que el balanceador de carga puede trabajar. Es importante que las subnets sean las mismas sobre las que se puede crear la instancia.

6.      resource "aws_lb_target_group" "test"
    Con este recurso se crea un target group al que el balanceador de carga redirigira las peticiones que se le hagan. Debe especificarse la *VPC* en el que se alojara y el *puerto* y *protocolo* que permitira. Es importante que estos atributos concuerden con los específicados para la instancia de EC2

7.      resource "aws_lb_target_group_attachment" "test"
    El único proposito de este recurso es el de acomplar la instancia de EC2 al target_group recien creado por lo que los unicos atributos a especificar son los arn de ambos recursos además del puerto por el que se conectaran.

8.      resource "aws_lb_listener" "web"
    Una de las partes centrales del balanceador de carga. Este recurso crea un listener que ejecutara las acciones definidas con las peticiones realizadas al balanceador de carga.
    Se le debe específicar el arn, puerto y protocolo del balanceador de carga y definir a traves de un bloque *default_action* la acción a realizar. Dentro de este se especifican:
    - *type*: La acción como tal a realizar. En este caso "forward" para redirigir al target group específicado.
    - *target_group_arn*: el arn del target group al que redirigit las peticiones.

Con estos recursos se logra levantar exitosamente un servidor web con un balanceador de carga. Sin embargo este se realizo con las configuraciones más basicas posibles para ser funcional por lo que cuenta con varios aspectos a mejorar. Para más información de los atributos que puede recibir cada recurso se recomienda el siguiente enlace, perteneciente a la documentación oficial de terraform.

- [Terraform registry](https://registry.terraform.io/)

## Actividad 2
###  Provisionamiento de Infra web con balanceador de carga con Autoscaling. 

Para esta segunda actividad se tomo como base el archivo .tf resultante de la actividad uno puesto que ambas infraestructuras comparten la mayor parte de los recursos (principalmente los relacionados al load balancer) y se realizaron los siguientes cambios:

1. Se añadio un segundo security group específico para el load balancer. Si bien en el resultado final estos son identicos esto se hizo pues se debería cambiar las reglas de ingreso para las instancia de EC2 de manera que solo permita que el balanceador de carga pueda hacerle peticiones.

2. Se cambio la instancia EC2 por un recurso de launch_configuration con los mismos atributos para que el grupo de auto escalado levante según se necesite instancias idénticas a partir de dichas configuraciones. 

3. Se añadieron los siguientes recursos:
-       resource "aws_autoscaling_group" "test"
    Este recurso define las especificaciones que tendra el grupo de autoescalado como lo son la cantidad mínima, deseada y máxima de instancia que se pueden mantener de manera simultanea, el nombre de la configuración que se usara para las instancias y la VPC donde se alojaran estas.


-       resource "aws_autoscaling_attachment" "test"

