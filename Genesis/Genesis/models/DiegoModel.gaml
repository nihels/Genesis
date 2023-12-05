/**
* Name: DiegoModel
* Based on the internal empty template. 
* Author: DiegoSaitta
* Tags: 
*/
model DiegoModel
global {
	//strade	
    file roads_shape_file <- file("../includes/road_suddivided.shp");
    geometry shape <- envelope(roads_shape_file);
    //incroci
    file nodes_shape_file <- shape_file("../includes/nodes_suddivided.shp");
    //edifici
    file shape_file_buildings <- file("../includes/PopBuild.shp");
  	list<building> residential_buildings;
	list<building> industrial_buildings;
	list<building> other_residential;
	
    //orari di lavoro
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16;
    int max_work_end <- 20;
    float min_distance <-15;
    //velocità
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 5.0 #km / #h;
    
    float step <- 0.20 #mn;
    date starting_date <- date("2019-09-01-00-00-00");

    list males<-[9,13,20];
	//list males<-[94,130,95,138,120,141,162,225,195,218,193,192,183,125,147,266];
    list females<-[9,12,23];
    //list females<-[91,102,109,119,124,164,162,201,196,201,207,199,189,148,163,395];
    
	int count_people <- 0;
    
    graph road_network;
    graph pedestrian_network;
    
   	list<car> cars <- [];
   	
   init{
		//creiamo gli edifici
        create building from: shape_file_buildings with: [type::string(read("NATURE"))] {
            if (name = "Chiesa di San Lorenzo Martire" or name = "Hotel Le Sorgenti") {
                color <- #red;
            } else {
                bool var0 <- flip(0.9);
                if var0 {
                    color <- #olive;
                    type <- "Residential";
                } else {
                    color <- #orange;
                    type <- "Industrial";
                }
            }
        }
        residential_buildings <- building where (each.type="Residential");
	    industrial_buildings <- building where (each.type="Industrial");
		other_residential <- building where (each.name = "Chiesa di San Lorenzo Martire" or each.name = "Hotel Le Sorgenti");
	
   		//creiamo la rete di connessioni fra le strade
   	    create intersection from: nodes_shape_file; 
   	     
   		//creiamo la rete stradale
    	create road from: roads_shape_file {
    		//creiamo un'altra strada in senso opposto
	         create road {
	                num_lanes <- myself.num_lanes;
	                shape <- polyline(reverse(myself.shape.points));
	                maxspeed <- myself.maxspeed;
	                linked_road <- myself;
	                myself.linked_road <- self;
            }
        }
		road_network <- as_driving_graph(road, intersection);
		
		//creiamo le auto e le inseriamo dentro la strada
      	create car number: 5 with: (location: one_of(intersection).location){
      		 add item: self to: cars;
      	}
   
   		loop i from: 0 to: length(males) - 1 {
	        create people number: males[i] {
	            color <- #green;
	            speed <- rnd(min_speed, max_speed);
	            start_work <- rnd(min_work_start, max_work_start);
	            end_work <- rnd(min_work_end, max_work_end);
	            living_place <- one_of(residential_buildings);
	            working_place <- one_of(industrial_buildings);
	            objective <- "resting";
	 			location <- any_location_in(living_place); // Set initial location inside a residential building
 				if(count_people <= length(cars)-1){
	 				self.personal_car <- cars[count_people];
	 				write("person : " + self + " go in the car: " + self.personal_car);
	 				car_target <- personal_car.location;
		 			count_people <- count_people+1;
 				}

	            size <- 5;
	        }
	    }
   	    		//loop i over:females{
		loop i from: 0 to: length(females)-1{
	       	create people number: females[i] {
	            color <- #pink;
	            inside_car <- false;
	            speed <- rnd(min_speed, max_speed);
	            start_work <- rnd(min_work_start, max_work_start);
	            end_work <- rnd(min_work_end, max_work_end);
	            living_place <- one_of(residential_buildings);
	            working_place <- one_of(industrial_buildings);
	            objective <- "resting";
 				location <- any_location_in(living_place); // Set initial location inside a residential building
 				if(count_people <= length(cars)-1){
 				personal_car <- cars[count_people];
 				car_target <- personal_car.location;
 				count_people <- count_people+1;			
 				}
 	        	size <- 5.0;
    		}
   	    }
   }


species road skills: [road_skill] {
    aspect default {
        draw shape color: #cadetblue end_arrow:2;
   }   
}
}
species intersection skills: [intersection_skill]{
	    aspect default {
        draw shape color: #red ;
   }   
} 

species car skills: [driving] {
	rgb color <- #blue;
	int capacity <- 2;
	point location <- nil;
	float size <- 20;
	int people_in <- nil;
	point driver_target <- nil;
	
	init 
	{	
		max_speed <- 20 #km / #h;
		max_acceleration <- 2.15;
	}
	
	   reflex move when: people_in != nil and driver_target !=nil {
	        path path_followed <- goto(target: driver_target, on: road_network, return_path: true);
	        list<geometry> segments <- path_followed.segments;
	        loop line over: segments {
	            float dist <- line.perimeter;
	        }
	        do drive;
	    }   
	   reflex select_next_path when: driver_target != nil and people_in != nil and current_path = nil{
		  	intersection node <- one_of(intersection);
			do compute_path graph: road_network target: node;
		}
	   reflex commute when: current_path != nil {
			do move;
		  		//do drive_random graph: road_network ;
		}
	  

	
	  aspect default 
	  {
			draw triangle(10,13) color: color rotate: heading + 90  border: #black;
	  }

}

species building {
    string type;
    rgb color <- #red;

    aspect default {
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
    car personal_car <- nil;
    point car_target;
    bool inside_car;
	reflex move {
	    // If the person has been assigned a car and is not yet in it
	    if (personal_car != nil and not inside_car) {
	        // Check if the person is close enough to enter the car
	        float distance <- distance_to(location,personal_car.location);
	        if (distance <= min_distance) {
	            // Enter the car
	            inside_car <- true;
	            personal_car.people_in <- personal_car.people_in + 1;
	        } else {
	            // Move towards the car
	            do goto target: personal_car.location;
	        }
	    } else if (inside_car and personal_car != nil) {
	        // If in car, update location to car's location
	        self.location <- personal_car.location;
	    } else {
	        // If the person has no car or has reached their car and is waiting to move
	        // Determine the target location based on the time of day and their objective
	        if (current_date.hour >= start_work and current_date.hour < end_work) {
	            // During working hours, move to work
	            the_target <- any_location_in(working_place);
	        } else {
	            // Outside of working hours, move to home
	            the_target <- any_location_in(living_place);
	        }
	        
	        // Move towards the target if it's not nil
	        if (the_target != nil) {
	            do goto target: the_target;
	        }
	    }
	
	 }
    aspect default {
        draw circle(size) color: color border: #black;
    }
} 	 
 experiment IntegratedCityExperiment type: gui {
    output {
        display city_display type: 2d {
            species building aspect: default;
            species road aspect:default;
            species intersection transparency: 0.9;
            species people aspect: default;
            species car aspect: default ;
        }
    }
}