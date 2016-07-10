function lautat(surf::TwoDSurf, curfield::TwoDFlowField, nsteps::Int64)
    outfile = open("results.dat", "w")

    dtstar = 0.015
    dt = dtstar*surf.c/surf.uref
    t = 0.

    #Intialise flowfield
    for istep = 1:nsteps
        #Udpate current time
        t = t + dt

        #Update kinematic parameters
        update_kinem(surf, t)

        #Update bound vortex positions
        update_boundpos(surf, dt)

        #Add a TEV with dummy strength
        place_tev(surf,curfield,dt)

        kelv = KelvinCondition(surf,curfield)
        #Solve for TEV strength to satisfy Kelvin condition
        #curfield.tev[length(curfield.tev)].s = secant_method(kelv, 0., -0.01)
        soln = nlsolve(not_in_place(kelv), [-0.01])
        curfield.tev[length(curfield.tev)].s = soln.zero[1]

        #Update adot
        update_a2a3adot(surf,dt)

        #Check for LEV and shed if yes
        #Set previous values of aterm to be used for derivatives in next time step
        surf.a0prev[1] = surf.a0[1]
        for ia = 1:3
            surf.aprev[ia] = surf.aterm[ia]
        end

        #Update rest of Fourier terms
        #update_a2toan(surf)

        #Calculate bound vortex strengths
        #update_bv(surf)

        #wakeroll(surf, curfield)

        cl, cd, cm = calc_forces(surf)
        write(outfile, join((t, surf.kinem.alpha, surf.kinem.h, surf.kinem.u, surf.a0[1], cl, cd, cm)," "), "\n")

    end
    close(outfile)

    #Plot flowfield viz and A0 history
    figure(0)
    view_vorts(surf, curfield)

end

function lautat_wakeroll(surf::TwoDSurf, curfield::TwoDFlowField, nsteps::Int64)
    outfile = open("results.dat", "w")

    dtstar = 0.015
    dt = dtstar*surf.c/surf.uref
    nsteps = 500
    t = 0.

    #Intialise flowfield
    for istep = 1:nsteps
        #Udpate current time
        t = t + dt

        #Update kinematic parameters
        update_kinem(surf, t)

        #Update bound vortex positions
        update_boundpos(surf, dt)

        #Add a TEV with dummy strength
        place_tev(surf,curfield,dt)

        kelv = KelvinCondition(surf,curfield)
        #Solve for TEV strength to satisfy Kelvin condition
        #curfield.tev[length(curfield.tev)].s = secant_method(kelv, 0., -0.01)
        soln = nlsolve(not_in_place(kelv), [-0.01])
        curfield.tev[length(curfield.tev)].s = soln.zero[1]

        #Update adot
        update_a2a3adot(surf,dt)

        #Check for LEV and shed if yes
        #Set previous values of aterm to be used for derivatives in next time step
        surf.a0prev[1] = surf.a0[1]
        for ia = 1:3
            surf.aprev[ia] = surf.aterm[ia]
        end

        #Update rest of Fourier terms
        update_a2toan(surf)

        #Calculate bound vortex strengths
        update_bv(surf)

        wakeroll(surf, curfield, dt)

        cl, cd, cm = calc_forces(surf)
        write(outfile, join((t, surf.kinem.alpha, surf.kinem.h, surf.kinem.u, surf.a0[1], cl, cd, cm)," "), "\n")

    end
    close(outfile)

    #Plot flowfield viz
    figure(0)
    view_vorts(surf, curfield)

end

function ldvmstep(surf::TwoDSurf_2DOF, curfield:: TwoDFlowField, dtstar::Float64 = 0.015)
    #Runs LDVM for a single time step - can be used as a continuation method for 2DOF airfoil. 
        
    dt = dtstar*surf.c/surf.uref
    
    #The kinematic paramters have already been updated - not prescribed
    
    #Update bound vortex positions
    update_boundpos(surf, dt)

    #Add a TEV with dummy strength
    place_tev(surf,curfield,dt)
    
    kelv = KelvinCondition2DOF(surf,curfield)
    #Solve for TEV strength to satisfy Kelvin condition
    #curfield.tev[length(curfield.tev)].s = secant_method(kelv, 0., -0.01)
    soln = nlsolve(not_in_place(kelv), [-0.01])
    curfield.tev[length(curfield.tev)].s = soln.zero[1]
    
    #Check for LESP condition
    #Update values with converged value of shed tev
    #Update incduced velocities on airfoil
    update_indbound(kelv.surf, kelv.field)
    
    #Calculate downwash
    update_downwash(kelv.surf)
    
    #Calculate first two fourier coefficients
    update_a0anda1(kelv.surf)
    
    lesp = surf.a0[1]
    
    #Update adot
    update_a2a3adot(surf,dt)
    
    #2D iteration if LESP_crit is exceeded
    if (abs(lesp)>surf.lespcrit[1])
        #Add a TEV with dummy strength
        place_tev(surf,curfield,dt)
        
        #Add a LEV with dummy strength
        place_lev(surf,curfield,dt)
        
        kelvkutta = KelvinKutta2DOF(surf,curfield)
        #Solve for TEV and LEV strengths to satisfy Kelvin condition and Kutta condition at leading edge
        
        soln = nlsolve(not_in_place(kelvkutta), [-0.01; 0.01])
        (curfield.tev[length(curfield.tev)].s, curfield.lev[length(curfield.lev)].s) = soln.zero[1], soln.zero[2]
        
        surf.levflag[1] = 1
    else
            surf.levflag[1] = 0
    end
    
    
    #Update rest of Fourier terms
    update_a2toan(surf)
    
    #Set previous values of aterm to be used for derivatives in next time step
    surf.a0prev[1] = surf.a0[1]
    for ia = 1:3
        surf.aprev[ia] = surf.aterm[ia]
    end
    
    #Calculate bound vortex strengths
    update_bv(surf)
    
    wakeroll(surf, curfield, dt)
    
    cl, cd, cm = calc_forces(surf)
    
    surf, curfield, cl, cd, cm
    
end


function ldvm(surf::TwoDSurf, curfield::TwoDFlowField, nsteps::Int64 = 500, dtstar::Float64 = 0.015)
    outfile = open("results.dat", "w")

    dt = dtstar*surf.c/surf.uref
    t = 0.

    #Intialise flowfield
    for istep = 1:nsteps
        #Udpate current time
        t = t + dt
        
        
        #Update kinematic parameters
        update_kinem(surf, t)

        #Update bound vortex positions
        update_boundpos(surf, dt)

        #Add a TEV with dummy strength
        place_tev(surf,curfield,dt)

        kelv = KelvinCondition(surf,curfield)
        #Solve for TEV strength to satisfy Kelvin condition
        #curfield.tev[length(curfield.tev)].s = secant_method(kelv, 0., -0.01)
        soln = nlsolve(not_in_place(kelv), [-0.01])
        curfield.tev[length(curfield.tev)].s = soln.zero[1]
        
        #Check for LESP condition
        #Update values with converged value of shed tev
        #Update incduced velocities on airfoil
        update_indbound(kelv.surf, kelv.field)

        #Calculate downwash
        update_downwash(kelv.surf)

        #Calculate first two fourier coefficients
        update_a0anda1(kelv.surf)

        lesp = surf.a0[1]

        #Update adot
        update_a2a3adot(surf,dt)

        #2D iteration if LESP_crit is exceeded
        if (abs(lesp)>surf.lespcrit[1])
            #Add a TEV with dummy strength
            place_tev(surf,curfield,dt)

            #Add a LEV with dummy strength
            place_lev(surf,curfield,dt)

            kelvkutta = KelvinKutta(surf,curfield)
            #Solve for TEV and LEV strengths to satisfy Kelvin condition and Kutta condition at leading edge

            soln = nlsolve(not_in_place(kelvkutta), [-0.01; 0.01])
            (curfield.tev[length(curfield.tev)].s, curfield.lev[length(curfield.lev)].s) = soln.zero[1], soln.zero[2]

            surf.levflag[1] = 1
        else
            surf.levflag[1] = 0
        end


        #Update rest of Fourier terms
        update_a2toan(surf)

        #Set previous values of aterm to be used for derivatives in next time step
        surf.a0prev[1] = surf.a0[1]
        for ia = 1:3
            surf.aprev[ia] = surf.aterm[ia]
        end

        #Calculate bound vortex strengths
        update_bv(surf)

        wakeroll(surf, curfield, dt)

        cl, cd, cm = calc_forces(surf)
        write(outfile, join((t, surf.kinem.alpha, surf.kinem.h, surf.kinem.u, surf.a0[1], cl, cd, cm)," "), "\n")
    end

    close(outfile)
    surf, curfield
    #Plot flowfield viz
#    figure(0)
#    view_vorts(surf, curfield)

end
