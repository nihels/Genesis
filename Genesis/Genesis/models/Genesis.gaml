/**
* Name: Genesis
* Based on the internal empty template. 
* Author: DiegoSaitta
* Tags: 
*/

model Genesis

global {
    
    // we import the .shp files
    file shape_file_buildings <- file("../includes/PopBuild (1).shp");
    file shape_file_roads <- file("../includes/finalrod.shp");
    file shape_file_bounds <- file("../includes/finalrod.shp");
    file nodes_shape_file <- shape_file("../includes/finalnodes.shp");
    
    geometry shape <- envelope(shape_file_bounds);
    float step <- 0.5 #mn;
    date starting_date <- date("2019-09-01-00-00-00");
    
    list males<-[94,130,95,138,120,141];
    list females<-[91,102,109,119,124];
    
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16;
    int max_work_end <- 20;
    
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 3.0 #km / #h;
    
    graph the_graph;
    
    graph road_network;
    
    list<building> residential_buildings;
    list<building> industrial_buildings;
    list<building> other_residential;
   
   init {
        create building from: shape_file_buildings with: [type::string(read("NATURE"))] {
            if (name = "Chiesa di San Lorenzo Martire" or name = "Hotel Le Sorgenti") {
                color <- #red;
            } else {
                bool var0 <- flip(0.9);
                if var0 {
                    color <- #skyblue;
                    type <- "Residential";
                } else {
                    color <- #orange;
                    type <- "Industrial";
                }
            }
        }
        create intersection from: nodes_shape_file;
        create road from: shape_file_roads {
        	create road {
				//num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				//maxspeed <- myself.maxspeed;
				//linked_road <- myself;
				//myself.linked_road <- self;
			}
        }
        road_network <- as_driving_graph(road, intersection);
        create vehicle number: 1000 with: (location: one_of(intersection).location);
        map<road, float> weights_map <- road as_map(each::(each.destruction_coeff * each.shape.perimeter));
        the_graph <- as_edge_graph(road,50) with_weights weights_map;

         residential_buildings <- building where (each.type="Residential");
         industrial_buildings <- building where (each.type="Industrial");
         other_residential <- building where (each.name = "Chiesa di San Lorenzo Martire" or each.name = "Hotel Le Sorgenti");
        
        
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
            //the_target <- any_location_in(one_of(other_residential)); // Corrected variable name
            
            size <- 5.0;
        }
    }
                //loop i over:females{
        loop i from: 0 to: length(females)-1{
            create people number: females[i] {
                color <- #pink;
                speed <- rnd(min_speed, max_speed);
                start_work <- rnd(min_work_start, max_work_start);
                end_work <- rnd(min_work_end, max_work_end);
                living_place <- one_of(residential_buildings);
                working_place <- one_of(industrial_buildings);
                objective <- "resting";
                location <- any_location_in(living_place); // Set initial location inside a residential building
                // the_target <- any_location_in(one_of(other_residential)); // Corrected variable name
                size <- 5.0;
            }
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

species intersection skills: [intersection_skill];

species vehicle skills: [driving] {
	rgb color <- rnd_color(255);
	init {
		vehicle_length <- 1.9 #m;
		max_speed <- 100 #km / #h;
		max_acceleration <- 3.5;
	}

	reflex select_next_path when: current_path = nil {
		// A path that forms a cycle
		do compute_path graph: road_network target: one_of(intersection);
	}
	
	reflex commute when: current_path != nil {
		do drive;
	}
	aspect base {
		draw triangle(5.0) color: color rotate: heading + 90 border: #black;
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

experiment city_people type: gui {
   output {
        display city_display type: 3d {
            species building aspect: base;
            species road aspect: base;
            species people aspect: base;
        }
    }
}