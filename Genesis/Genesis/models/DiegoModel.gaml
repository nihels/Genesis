/**
* Name: DiegoModel
* Based on the internal empty template. 
* Author: DiegoSaitta
* Tags: 
*/


model DiegoModel

/* Insert your model definition here */

global {
	//strade	
    file roads_shape_file <- file("../includes/FinRod1.shp");
    file nodes_shape_file <- shape_file("../includes/finalnodes.shp");
	//shape_file nodes_shape_file <- shape_file("../includes/Tutorials/nodes.shp");
	//shape_file roads_shape_file <- shape_file("../includes/Tutorials/roads.shp");
    geometry shape <- envelope(roads_shape_file);
    graph road_network;
    
    //edifici
    file shape_file_buildings <- file("../includes/PopBuild.shp");
  	list<building> residential_buildings;
	list<building> industrial_buildings;
	list<building> other_residential;
	
	
	//variabili temporali
    //float step <- 0.8 #mn;
    //date starting_date <- date("2019-09-01-00-00-00");
    //graph pedestrian_network;


   	list<car> cars;
   	
   	
    init{
   		//creiamo la rete di connessioni fra le strade
   	    create intersection from: nodes_shape_file; 
   	     
   		//creiamo le strade
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

		//uniamo le strade in un network
		road_network <- as_driving_graph(road, intersection);
		
		//creiamo le auto e le inseriamo dentro la strada
      	create car number: 15 with: (location: one_of(intersection).location){
      		cars <-car;
      	}
      	
      	//creiamo gli edifici
        create building from: shape_file_buildings with: [type::string(read("NATURE"))] {
            if (name = "Chiesa di San Lorenzo Martire" or name = "Hotel Le Sorgenti") {
                color <- #red;
            } 
            else {
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
   }

	species intersection skills: [intersection_skill] ;

	species road skills: [road_skill] {
	    aspect base {
	        draw shape color: #cadetblue end_arrow:3;
	   }   
	}

	species car skills: [driving] {
		rgb color <- #blue;
		//list<people> people_inside ;
		//int n_of_people_in <- nil;
		point driver_target;
		init{	
			max_speed <- 50 #km / #h;
			max_acceleration <- 0.15;
		}

  	 	reflex select_next_path when: current_path = nil {
			do compute_path graph: road_network target: one_of(intersection);
		}
  		reflex commute when: current_path != nil {
			//do drive_random graph: road_network ;
			do drive;
		}
		aspect base {
			draw triangle(10.0) color: color rotate: heading + 90 border: #black;
		}
	}  
	
	species building {
    	string type;
    	rgb color <- #red;
	    aspect base {
	        draw shape color: color;
	    }
	}
}

experiment IntegratedCityExperiment type: gui {
    output synchronized: true{
        display city_display type: 3d background: #white{
            species building aspect:base;
            species road aspect:base;
            species car aspect: base;
            //species people aspect: base;
        }
    }
}

