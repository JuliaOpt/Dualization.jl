@testset "rsoc problems" begin
    @testset "rsoc1_test" begin
    #=
    primal
        min 0a + 0b - 1x - 1y
    s.t.
        a    == 1/2
        b    == 1
        2a*b >= x^2+y^2
   
   dual

       
   =#
       primal_model = rsoc1_test()
       dual_model, primal_dual_map = get_dual_model_and_map(primal_model)

       @test MOI.get(dual_model, MOI.NumberOfVariables()) == 6
       list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
       @test list_of_cons == [
           (SAF{Float64}, MOI.EqualTo{Float64})              
           (VVF, MOI.RotatedSecondOrderCone)
       ]
       @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.RotatedSecondOrderCone}()) == 1   
       @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 4
       obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
       @test obj_type == SAF{Float64}
       obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
       @test MOI.get(dual_model, MOI.ObjectiveSense())
       @test MOI._constant(obj) == 0.0
       @test MOI.coefficient.(obj.terms) == [-1.0; -0.5]
       
       eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
       @test MOI._constant.(eq_con1_fun) == 0.0
       @test MOIU.getconstant(eq_con1_set) == 0.0
       eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       @test MOI.coefficient.(eq_con2_fun.terms) == [1.0]
       @test MOI._constant.(eq_con2_fun) == 0.0
       @test MOIU.getconstant(eq_con2_set) == -1.0
       eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
       @test MOI._constant.(eq_con3_fun) == 0.0
       @test MOIU.getconstant(eq_con3_set) == -1.0

       soc_con = MOI.get(dual_model, MOI.ConstraintFunction(), CI{VVF, MOI.SecondOrderCone}(1))
       @test soc_con.variables == VI.(1:3)

       primal_con_dual_var = primal_dual_map.primal_con_dual_var
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.Zeros}(1)] == [VI(4)]
       @test primal_con_dual_var[CI{VVF, MOI.SecondOrderCone}(2)] == [VI(1); VI(2); VI(3)]

       primal_var_dual_con = primal_dual_map.primal_var_dual_con
       @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
       @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
       @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
   end

   @testset "soc2_test" begin
    #=
    primal
        min 0a + 0b - 1x - 1y
    s.t.
        a    == 1/2
        b    == 1
        2a*b >= x^2+y^2
   
    dual
        
   =#
       primal_model = soc2_test()
       dual_model, primal_dual_map = get_dual_model_and_map(primal_model)

       @test MOI.get(dual_model, MOI.NumberOfVariables()) == 4
       list_of_cons =  MOI.get(dual_model, MOI.ListOfConstraints())
       @test list_of_cons == [
           (SAF{Float64}, MOI.EqualTo{Float64})              
           (VVF, MOI.SecondOrderCone)
       ]
       @test MOI.get(dual_model, MOI.NumberOfConstraints{VVF, MOI.SecondOrderCone}()) == 1   
       @test MOI.get(dual_model, MOI.NumberOfConstraints{SAF{Float64}, MOI.EqualTo{Float64}}()) == 3
       obj_type = MOI.get(dual_model, MOI.ObjectiveFunctionType())
       @test obj_type == SAF{Float64}
       obj = MOI.get(dual_model, MOI.ObjectiveFunction{obj_type}())
       @test MOI._constant(obj) == 0.0
       @test MOI.coefficient.(obj.terms) == [-1.0]
       
       eq_con1_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       eq_con1_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(2))
       @test MOI.coefficient.(eq_con1_fun.terms) == [1.0; 1.0]
       @test MOI._constant.(eq_con1_fun) == 0.0
       @test MOIU.getconstant(eq_con1_set) == 0.0
       eq_con2_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       eq_con2_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(3))
       @test MOI.coefficient.(eq_con2_fun.terms) == [1.0]
       @test MOI._constant.(eq_con2_fun) == 0.0
       @test MOIU.getconstant(eq_con2_set) == -1.0
       eq_con3_fun = MOI.get(dual_model, MOI.ConstraintFunction(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       eq_con3_set = MOI.get(dual_model, MOI.ConstraintSet(), CI{SAF{Float64}, MOI.EqualTo{Float64}}(4))
       @test MOI.coefficient.(eq_con3_fun.terms) == [1.0]
       @test MOI._constant.(eq_con3_fun) == 0.0
       @test MOIU.getconstant(eq_con3_set) == -1.0

       soc_con = MOI.get(dual_model, MOI.ConstraintFunction(), CI{VVF, MOI.SecondOrderCone}(1))
       @test soc_con.variables == VI.(2:4)

       primal_con_dual_var = primal_dual_map.primal_con_dual_var
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.Zeros}(1)] == [VI(1)]
       @test primal_con_dual_var[CI{VAF{Float64}, MOI.SecondOrderCone}(2)] == [VI(2); VI(3); VI(4)]

       primal_var_dual_con = primal_dual_map.primal_var_dual_con
       @test primal_var_dual_con[VI(1)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(2)
       @test primal_var_dual_con[VI(2)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(3)
       @test primal_var_dual_con[VI(3)] == CI{SAF{Float64}, MOI.EqualTo{Float64}}(4)
   end
end