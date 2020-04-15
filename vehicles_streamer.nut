/**
  * @author Xmair
  * @name Vehicles streamer
  * @description Creates vehicles when players are in an X radius
  * @disclaimer Might lag on a server with more players
  */

/**
  * Edit these according to your will
  */

const SQ_VEHICLE_STREAMER_TIMER     = 500;
const SQ_VEHICLE_STREAMER_MIN_DIST  = 50;

class SqVehicleStreamer {
    /**
      * @description Table to store all vehicles
      */
    static VEHICLES       = {};

    /**
      * @params id: ID of the vehicle,
                model: Model of the vehicle,
                world: World of the vehicle,
                position: Position of the vehicle,
                angle: Angle of the vehicle,
                primaryColour: Primary Colour (Colour 1) of the vehicle,
                secondaryColour: Secondary Colour (Colour 2) of the vehicle,
      * @description Function to add a vehicle into the streamer
      * @returns Nothing
      */
    static function addVehicle(id, model, world, position, angle, primaryColour, secondaryColour) {
        if (SqVehicleStreamer.vehicleExists(id) == true) throw format("Vehicle ID %i already exists.", id);

        SqVehicleStreamer.VEHICLES.rawset(id, [model, world, position, angle, primaryColour, secondaryColour, ::SqVehicle.Create(model, world, position, angle, primaryColour, secondaryColour)]);
    }

    /**
      * @params id: ID of the vehicle
      * @description Function used by the streamer to create a vehicle
      * @returns Nothing
      */
    static function createVehicle(id) {
        if (SqVehicleStreamer.vehicleExists(id) == false) throw format("Vehicle ID %i doesn't exist.", id);
        if (SqVehicleStreamer.VEHICLES.rawget(id)[6] != null) throw format("Vehicle ID %i is already created.", id);

        local vehicle     = SqVehicleStreamer.VEHICLES.rawget(id);

        SqVehicleStreamer.VEHICLES.rawdelete(id);
        SqVehicleStreamer.VEHICLES.rawset(id, [vehicle[0], vehicle[1], vehicle[2], vehicle[3], vehicle[4], vehicle[5], ::SqVehicle.Create(vehicle[0], vehicle[1], vehicle[2], vehicle[3], vehicle[4], vehicle[5])]);
    }

    /**
      * @params id: ID of the vehicle
      * @description Function used by the streamer to destroy a vehicle
      * @returns Nothing
      */
    static function destroyVehicle(id) {
        if (SqVehicleStreamer.vehicleExists(id) == false) throw format("Vehicle ID %i doesn't exist.", id);

        local vehicle     = SqVehicleStreamer.VEHICLES.rawget(id);

        if (vehicle[6] != null)
            vehicle[6].Destroy();

        SqVehicleStreamer.VEHICLES.rawdelete(id);
        SqVehicleStreamer.VEHICLES.rawset(id, [vehicle[0], vehicle[1], vehicle[2], vehicle[3], vehicle[4], vehicle[5], null]);
    }

    /**
      * @params id: ID of the vehicle
      * @description Function to remove a vehicle from the streamer
      * @returns Nothing
      */
    static function removeVehicle(id) {
        if (SqVehicleStreamer.vehicleExists(id) == false) throw format("Vehicle ID %i doesn't exist.", id);

        local vehicle     = SqVehicleStreamer.VEHICLES.rawget(id);
        
        if (vehicle[6] != null)
            vehicle[6].Destroy();
        SqVehicleStreamer.VEHICLES.rawdelete(id);
    }

    /**
      * @params id: ID of the vehicle
      * @description Function to check if a vehicle exists in the streamer
      * @returns true if vehicle exists in the streamer, false if not
      */
    static function vehicleExists(id) {
        return SqVehicleStreamer.VEHICLES.rawin(id);
    }

    /**
      * @description Function to get the number of vehicles in the streamer
      * @returns integer: count
      */
    static function getVehicleCount() {
        return SqVehicleStreamer.VEHICLES.len();
    }

    /**
      * @description Function to get vehicles in the streamer
      * @returns array: first index include the active vehicles and second index includes the inactive vehicles
      */
    static function getVehicles() {
        local active       = {};
        local inactive     = {};
        foreach(idx, inst in SqVehicleStreamer.VEHICLES) {
            if (inst[6] != null)
                active.rawset(idx, inst);
            else
                inactive.rawset(idx, inst);
        }

        return [active, inactive];
    }
    
    /**
      * @description Main checking function
      * @returns Nothing
      */
    static function check() {
        local vehicles     = SqVehicleStreamer.getVehicles();
        if (SqCount.Player.Active() > 0) {
            if (vehicles[0].len() > 0) {
                foreach(idx, inst in vehicles[0]) {
                    local playersNear      = 0;

                    SqForeach.Player.Active(this, function(player) {
                        if (player.Spawned && player.World == inst[1] && player.Pos.DistanceTo(inst[6].Pos) < SQ_VEHICLE_STREAMER_MIN_DIST) {
                            ++ playersNear;
                        }
                    });

                    if (playersNear == 0) {
                        SqVehicleStreamer.destroyVehicle(idx);
                    }
                }
            }

            if (vehicles[1].len() > 0) {
                SqForeach.Player.Active(this, function(player) {
                    if (player.Spawned) {
                        foreach(idx, inst in vehicles[1]) {
                            if (player.World == inst[1] && player.Pos.DistanceTo(inst[2]) < SQ_VEHICLE_STREAMER_MIN_DIST) {
                                SqVehicleStreamer.createVehicle(idx);
                            }
                        }
                    }
                });
            }
        }
    }
}

/*
 * You may add vehicles from here by using the following syntax:
 * SqVehicleStreamer.addVehicle(id, model, world, position, angle, primaryColour, secondaryColour);
 */

SqRoutine(this, SqVehicleStreamer.check, SQ_VEHICLE_STREAMER_TIMER, 0)
    .Quiet    = false;