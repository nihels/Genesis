/**
* Name: Genesis
* Based on the internal empty template. 
* Author: DiegoSaitta
* Tags: 
*/


model Genesis
import "Variabili.gaml"
global {
	file shape_file_buildings <- file("../includes/Oct2023.shp");
    file shape_file_roads <- file("../includes/PRoads.shp");
    file shape_file_bounds <- file("../includes/Oct2023.shp");
    geometry shape <- envelope(shape_file_bounds);
    float step <- 0.3 #mn;
    date starting_date <- date("2019-09-01-00-00-00");
      
	

    int nb_females_0_4 <- 3;
    
    //counter[0] = 0_4 age , counter[1] = 5_9 age, counter[2] = 10_14 age, counter[3] = 15_19 age, counter[4] = 0_4 age. 
    list males<-[1,2,3,4];
    list females<-[1,2,3,4];
    
    int nb_people_m <- 30;  // Number of female people
    int nb_people_f <- 30;  // Number of female people
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16;
    int max_work_end <- 20;
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 5.0 #km / #h;
    graph the_graph;

    init {
        create building from: shape_file_buildings with: [type::string(read ("NATURE"))] {
        	bool var0 <- flip (0.3);
        	//type = flip("Residential","Industrial");
            if var0 {
                color <- #blue;
                type <- "Residential";
            }else{
        	   color <- #gray;
        	   type <- "Industrial";
            }
        }
        create road from: shape_file_roads;
        map<road, float> weights_map <- road as_map(each::(each.destruction_coeff * each.shape.perimeter));
        the_graph <- as_edge_graph(road,50) with_weights weights_map;

        list<building> residential_buildings <- building where (each.type="Residential");
        list<building> industrial_buildings <- building where (each.type="Industrial");
		
		loop i from: 0 to: 20{
	       	create people number: i {
	            color <- #red;
	            speed <- rnd(min_speed, max_speed);
	            start_work <- rnd(min_work_start, max_work_start);
	            end_work <- rnd(min_work_end, max_work_end);
	            living_place <- one_of(residential_buildings);
	            working_place <- one_of(industrial_buildings);
	            objective <- "resting";
	            location <- any_location_in(living_place);
	        	
	        	size <-  5;
    		}
   	    }
   	    		//loop i over:females{
		loop i from: 0 to: 20{
	       	create people number: i {
	            color <- #pink;
	            speed <- rnd(min_speed, max_speed);
	            start_work <- rnd(min_work_start, max_work_start);
	            end_work <- rnd(min_work_end, max_work_end);
	            living_place <- one_of(residential_buildings);
	            working_place <- one_of(industrial_buildings);
	            objective <- "resting";
	            location <- any_location_in(living_place);
	  
	        	size <- 5;
    		}
   	    }
	}
}

    


species building {
    string type;
    rgb color <- #gray;

    aspect base {
        draw shape color: color;
    }
}

species road {
    float destruction_coeff <- rnd(1.0, 2.0) max: 2.0;
    //int colorValue <- int(255 * (destruction_coeff - 1)) update: int(255 * (destruction_coeff - 1));
    //rgb color <- rgb(min([255, colorValue]), max([0, 255 - colorValue]), 0) update: rgb(min([255, colorValue]), max([0, 255 - colorValue]), 0);
	rgb color <- #black;
    aspect base {
        draw shape color: color;
    }
}

species people skills:[moving] {
    rgb color <- #blue;
    building living_place <- nil;
    building working_place <- nil;
    int start_work;
    int end_work;
    string objective;
    point the_target <- nil;
    float size;

    // Set age-specific attributes

    reflex time_to_work when: current_date.hour = start_work and objective = "resting" {
        objective <- "working";
        the_target <- any_location_in(working_place);
    }

    reflex time_to_go_home when: current_date.hour = end_work and objective = "working" {
        objective <- "resting";
        the_target <- any_location_in(living_place);
    }

    reflex move when: the_target != nil {
        path path_followed <- goto(target: the_target, on: the_graph, return_path: true);
        list<geometry> segments <- path_followed.segments;
        loop line over: segments {
            float dist <- line.perimeter;
            
        }
        if the_target = location {
            the_target <- nil;
        }
    }
   



    aspect base {
        draw circle(size) color: color border: #black;
    }
}


experiment road_traffic type: gui {
		//parameter "0 - 4" var: nb_males_0_4 category: "people" ;
	//	parameter "5 - 9" var: nb_males_5_9 category: "people" ;
	//	parameter "10 -14" var: nb_males_10_14 category: "people" ;
	//	parameter "f 0_4" var: nb_females_0_4 category: "people" ;
		
	
    output {
        display city_display type: 3d {
            species building aspect: base;
            species road aspect: base;
            species people aspect: base;
        }
    }
}

/* Insert your model definition here */

