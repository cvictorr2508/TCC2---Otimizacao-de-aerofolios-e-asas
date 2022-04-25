import openvsp as vsp


#// Created by Justin Gravett, ESAero, 2/28/20


print(  "Begin VSPAERO Actuator Disk & Control Surface Group Analysis" ) 
# Print( string( "" ) );


#//==== Create an example model ====//
print( "--> Generating Geometries" ) 
# print( string( "" ) );

pod_id = vsp.AddGeom( "POD", "" )
wing_id = vsp.AddGeom( "WING", pod_id )

vsp.SetParmVal( wing_id, "X_Rel_Location", "XForm", 2.5 )
vsp.SetParmVal( wing_id, "TotalArea", "WingGeom", 25 )
vsp.SetParmVal( wing_id, "SectTess_U", "XSec_1", 12 )

# // Add a subsurface and create a control surface group
subsurf_id = vsp.AddSubSurf( wing_id, SS_CONTROL, 0 )

group_index = vsp.CreateVSPAEROControlSurfaceGroup() # // Empty control surface group

cs_group_name = "Example_CS_Group"
vsp.SetVSPAEROControlGroupName( cs_group_name, group_index )

available_cs_vec = vsp.GetAvailableCSNameVec( group_index )
array < int > cs_index_vec
cs_index_vec.push_back( 1 )
cs_index_vec.push_back( 2 )
# // Input cs_index_vec corresponds to the available control surfaces returned by GetAvailableCSNameVec
vsp.AddSelectedToCSGroup( cs_index_vec, group_index ); #// cs_index_vec must be one based

// Check that the control surface was added to the group
array<string> active_cs_vec = GetActiveCSNameVec( group_index );
if ( active_cs_vec[0] != available_cs_vec[0] )
{
    Print( "ERROR: Available control surface not added to the group" );
}

Update();

// Set the control surface deflections
string cs_group_container_id = FindContainer( "VSPAEROSettings", 0 );

// Set the gain on one side of the control surface positive and the other side negative
// for the overall deflection to be symmetric (pitch= vs roll moment)
SetParmVal( FindParm( cs_group_container_id, "Surf_" + subsurf_id + "_0_Gain", "ControlSurfaceGroup_0" ), 1 );
SetParmVal( FindParm( cs_group_container_id, "Surf_" + subsurf_id + "_1_Gain", "ControlSurfaceGroup_0" ), -1 );
SetParmVal( FindParm( cs_group_container_id, "DeflectionAngle", "ControlSurfaceGroup_0" ), 10 ); // degrees

vsp.Update();

# // Create an actuator disk
string prop_id = AddGeom( "PROP", pod_id );
SetParmVal( prop_id, "PropMode", "Design", PROP_DISK );
SetParmVal( prop_id, "Diameter", "Design", 6.0 );
SetParmVal( prop_id, "X_Rel_Location", "XForm", -0.25 );

vsp.Update();

// Setup the actuator disk VSPAERO parms
string disk_id = FindActuatorDisk( 0 );
SetParmVal( FindParm( disk_id, "RotorRPM", "Rotor" ), 1234.0 );
SetParmVal( FindParm( disk_id, "RotorCT", "Rotor" ), 0.35 );
SetParmVal( FindParm( disk_id, "RotorCP", "Rotor" ), 0.55 );
SetParmVal( FindParm( disk_id, "RotorHubDiameter", "Rotor" ), 1.0 );

Update();

//==== Setup export filenames ====//
string fname_vspaerotests = "VSPAero_Disk.vsp3";

//==== Save Vehicle to File ====//
Print( "-->Saving vehicle file to: ", false );
Print( fname_vspaerotests, true );
Print( "" );
WriteVSPFile( fname_vspaerotests, SET_ALL );
Print( "COMPLETE\n" );
Update();

//==== Analysis: VSPAero Compute Geometry to Create Vortex Lattice DegenGeom File ====//
string compgeom_name = "VSPAEROComputeGeometry";
Print( compgeom_name );

// Set defaults
SetAnalysisInputDefaults( compgeom_name );

// Analysis method
array< int > analysis_method = GetIntAnalysisInput( compgeom_name, "AnalysisMethod" );
analysis_method[0] = ( VSPAERO_ANALYSIS_METHOD::VORTEX_LATTICE );
SetIntAnalysisInput( compgeom_name, "AnalysisMethod", analysis_method );

// list inputs, type, and current values
PrintAnalysisInputs( compgeom_name );

// Execute
Print( "\tExecuting..." );
string compgeom_resid = ExecAnalysis( compgeom_name );
Print( "COMPLETE" );

// Get & Display Results
PrintResults( compgeom_resid );

//==== Analysis: VSPAero Single Point ====//
string analysis_name = "VSPAEROSinglePoint";

SetAnalysisInputDefaults( analysis_name );

// Reference geometry set
array< int > geom_set;
geom_set.push_back( 0 );
SetIntAnalysisInput( analysis_name, "GeomSet", geom_set, 0 );
array< int > ref_flag;
ref_flag.push_back( 1 );
SetIntAnalysisInput( analysis_name, "RefFlag", ref_flag, 0 );
array< string > wid = FindGeomsWithName( "WingGeom" );
SetStringAnalysisInput( analysis_name, "WingID", wid, 0 );

// Freestream Parameters
array< double > alpha;
alpha.push_back( 0.0 );
SetDoubleAnalysisInput( analysis_name, "Alpha", alpha, 0 );
array< double > mach;
mach.push_back( 0.1 );
SetDoubleAnalysisInput( analysis_name, "Mach", mach, 0 );

Update();

// list inputs, type, and current values
PrintAnalysisInputs( analysis_name );
Print( "" );

// Execute
Print( "\tExecuting..." );
string rid = ExecAnalysis( analysis_name );
Print( "COMPLETE" );

// Get & Display Results
PrintResults( rid );

array<string> results_names = GetAllDataNames( rid );
array<string>res_id = GetStringResults( rid, results_names[1] , 0 ); // Note: first result name is "AnalysisDurationSec"

array<double> CL = GetDoubleResults( res_id[0], "CL", 0 );
array<double> cl = GetDoubleResults( res_id[1], "cl", 0 );

