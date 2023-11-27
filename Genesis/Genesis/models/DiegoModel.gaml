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
    //file shape_file_buildings <- file("../includes/PopBuild.shp");
  	//list<building> residential_buildings;
	//list<building> industrial_buildings;
	//list<building> other_residential;
	
	
    //float step <- 0.10 #mn;
    date starting_date <- date("2019-09-01-00-00-00");
    //graph pedestrian_network;


   	list<car> cars;
   	
   	
   init{
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
      	create car number: 15 with: (location: one_of(intersection).location){
      		cars <-car;
      	}
   }


species road skills: [road_skill] {
    aspect default {
        draw shape color: #cadetblue end_arrow:2;
   }   
}
}
species intersection skills: [intersection_skill] ;

species car skills: [advanced_driving] {
	rgb color <- #blue;
	//list<people> people_inside ;
	//int n_of_people_in <- nil;
	point driver_target;
	init 
	{	
		max_speed <- 5 #km / #h;
		max_acceleration <- 0.15;
	}

  reflex select_next_path when: current_path = nil {
		do compute_path graph: road_network target: one_of(intersection);
	}
  reflex commute when: current_path != nil {
		//do drive_random graph: road_network ;
		do drive;
		
	}
	
  aspect base 
  {
		draw rectangle(20,6) color: color rotate: heading  border: #black;
	}
	   species building {
    string type;
    rgb color <- #red;

    aspect base {
        draw shape color: color;
    }
}
	
}experiment IntegratedCityExperiment type: gui {
    output {
        display city_display type: 3d {
            species building aspect:base;
            species road aspect:default;
            //species people aspect: base;
            species car aspect: base;
        }
    }
}