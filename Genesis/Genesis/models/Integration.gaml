model IntegratedCityModel

global {
    // Shared shape files and global variables
    file shape_file_buildings <- file("../includes/PopBuild.shp");
    file shape_file_roads <- file("../includes/FinRod1.shp");
    file nodes_shape_file <- shape_file("../includes/finalnodes.shp");
    geometry shape <- envelope(nodes_shape_file);
    float step <- 0.10 #mn;
    date starting_date <- date("2019-09-01-00-00-00");
    list males<-[9,13,20];
    list females<-[9,12,23];
	list<people>  multipeople;
	
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16;
    int max_work_end <- 20;
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 1.2 #km / #h;
    graph pedestrian_network;
    graph car_network;
   	list<building> residential_buildings;
	list<building> industrial_buildings;
	list<building> other_residential;
	list<car> cars;
	list<point> checkpoint;
	
    init {
        
        // Unified initialization for both road and building networks
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
        
	 	create road from: shape_file_roads {
	         create road {
	                num_lanes <- myself.num_lanes;
	                shape <- polyline(reverse(myself.shape.points));
	                maxspeed <- myself.maxspeed;
	                linked_road <- myself;
	                myself.linked_road <- self;
            }
        }	
        
        create intersection from: nodes_shape_file; // Initialize intersections 
          
        // Create a unified road network for both cars and people      
        pedestrian_network <- as_edge_graph(road, 50) ;
        car_network <- as_driving_graph(road, intersection);
          
      	create car number: 15 { 
	  		location  <- one_of(intersection).location;
	  		cars <- car;
        } 
        
        //create males people
        loop i from: 0 to: length(males) - 1 {
        	create people number: males[i] {
	         	multipeople <- people;
	            color <- #dodgerblue;
	            speed <- rnd(min_speed, max_speed);
	            start_work <- rnd(min_work_start, max_work_start);
	            end_work <- rnd(min_work_end, max_work_end);
	            living_place <- one_of(residential_buildings);
	            working_place <- one_of(industrial_buildings);
	            objective <- "resting";
	 			location <- any_location_in(living_place); // Set initial location inside a residential building
	            size <- 5;
        	}
    	}
   	    
   	    //create females people
		loop i from: 0 to: length(females)-1{
	    	create people number: females[i] {
	       		multipeople <- people;
	            color <- #salmon;
	            speed <- rnd(min_speed, max_speed);
	            start_work <- rnd(min_work_start, max_work_start);
	            end_work <- rnd(min_work_end, max_work_end);
	            living_place <- one_of(residential_buildings);
	            working_place <- one_of(industrial_buildings);
	            objective <- "resting";
 				location <- any_location_in(living_place); // Set initial location inside a residential building
 	        	size <- 5;
    		}
   	    }
   	    
		loop i from:0 to:length(cars)-1 { 
			people this_person <- one_of(multipeople); 
			this_person.personal_car <- cars[i]; 
			cars[i].location <- this_person.living_place; 
			this_person.car_target <- this_person.personal_car.location; 
        }  
        
    }
    
}

species building {
    string type;
    rgb color <- #red;

    aspect base {
        draw shape color: color;
    }
}

species road skills: [road_skill] {
    aspect default {
        draw shape color: #cadetblue end_arrow: 3;
   }   
}

species intersection skills: [skill_road_node] ;


species people skills:[moving] {
	bool has_car<-false;
	car personal_car <-nil;
	point car_target <-nil;
    rgb color <- #blue;
    building living_place <- nil;
    building working_place <- nil;
    int start_work;
    int end_work;
    string objective;
    point the_target <- nil;
    float size;
    bool in_car <- false;   
    bool exited <- false;
    
    //change objecting to working
    reflex time_to_work when: current_date.hour = start_work and objective = "resting" {
    	write "it's time to work";
        objective <- "working";
        the_target <- any_location_in(working_place);
    }

	//change objecting to resting
  	reflex time_to_go_home when: current_date.hour = end_work and objective = "working" {
        write "it's time to go home";
        objective <- "resting";
        the_target <- any_location_in(living_place);
        
    }
    
    reflex switch_objectives when: (current_date.hour = start_work or current_date.hour = end_work) and exited {
    	exited <- false;
    }

	//people movement when a person don't have a car
  	reflex move when: the_target != nil and personal_car=nil or exited{ 
        path path_followed <- goto(target: the_target, on: pedestrian_network, return_path: true); 
        list<geometry> segments <- path_followed.segments; 
        loop line over: segments { 
            float dist <- line.perimeter;     
        } 
        if the_target = location { 
            the_target <- nil; 
        } 
    } 
    
    //We need something that say to us when the objective became resting from working or 
    //working from resting, in that case we put exited=false;
    
 	//people movement when a person who have a car
  	reflex move_with_car when: personal_car!=nil and !exited{ 
		if(!in_car) { 
        	path path_followed <- goto(target: personal_car.location, on: pedestrian_network, return_path: true); 
	        list<geometry> segments <- path_followed.segments; 
	        loop line over: segments { 
	            float dist <- line.perimeter; 
	        }  
        	if(distance_to(self.location, personal_car.location) <= 5.0){ 
		        in_car <- true;
		        self.location <- personal_car.location;
		        personal_car.n_of_people_in <- personal_car.n_of_people_in +1; 
		        add self to:personal_car.people_inside;
         	} 
		} else { 
	    	self.location <- personal_car.location;
      	}
      	
     }
     
	aspect base {
        draw circle(size) color: color border: #black;
	}
	
}

species car skills: [driving] {
	rgb color <- #blue;
	list<people> people_inside ;
	int n_of_people_in <- 0;
	point actual_target;
	init {	
		max_speed <- 5 #km / #h;
		max_acceleration <- 0.15;
	}

  	reflex select_next_path when: current_path = nil {
		do compute_path graph: car_network target: any(intersection);
	}
	
	/* 
  	reflex commute when: current_path != nil {
		do drive;
	}
	*/
	
	reflex move_car when: n_of_people_in > 0{
		actual_target <- people_inside[0].the_target;
		if (actual_target != nil) {
            // If there are people in the car and a target is set, move towards the target
            //do goto target: actual_target;
            destination <- actual_target;
            do drive;
            if (distance_to(self.location, actual_target) <= 20.0) { // Assuming 5.0 is a proximity threshold
                // Reset the target upon reaching the destination
                actual_target <- nil;
                people_inside[0].in_car <- false;
                people_inside[0].exited <- true;
                n_of_people_in <- n_of_people_in -1;
                remove from:people_inside index:length(people_inside)-1;
            }
        }
		
		/*
		loop i from:length(people_inside)-1 to:0 {
			actual_target <- people_inside[i].the_target;
			if (actual_target != nil) {
	            // If there are people in the car and a target is set, move towards the target
	            do goto target: actual_target;
	            if (distance_to(location, actual_target) <= 5.0) { // Assuming 5.0 is a proximity threshold
	                // Reset the target upon reaching the destination
	                actual_target <- nil;
	                n_of_people_in <- n_of_people_in -1;
	                remove from:people_inside index:length(people_inside)-1;
	            }
	        }
		}  
		*/
    }	
	
	aspect base {
		draw rectangle(20,6) color: color rotate: heading  border: #black;
	}
	
}


experiment IntegratedCityExperiment type: gui {
    output {
        display city_display type: 2d {
            species building aspect:base;
            species road aspect:default;
            species people aspect: base;
            species car aspect: base;
            species intersection;
        }
    }
}


