/**
* Name: Variabili
* Based on the internal empty template. 
* Author: DiegoSaitta
* Tags: 
*/


model Variabili
global {
	file shapefile_building <- file("../includes/Oct2023.shp");
    file shape_file_roads <- file("../includes/rrr.shp");
    file shape_file_bounds <- file("../includes/Tutorials/bounds.shp");
    geometry shape <- envelope(shape_file_bounds);
    float step <- 0.3 #mn;
    date starting_date <- date("2019-09-01-00-00-00");
    int nb_people <- (nb_males_0_4 + nb_males_5_9 + nb_males_10_14 +nb_females_0_4 );  // Number of male people
    int nb_males_0_4 <- 1;
    int nb_males_5_9 <- 2;
    int nb_males_10_14 <- 3;
    
    int nb_females_0_4 <- 3;
    
        
    int counter_0_4 <- 0;
    int counter_5_9 <- 0;
    int counter_10_14 <- 0;
    
    int counter_f_0_4 <- 0;
    
    
    int nb_people_f <- 20;  // Number of female people
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16;
    int max_work_end <- 20;
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 5.0 #km / #h;
    graph the_graph;
    
    }
/* Insert your model definition here */

