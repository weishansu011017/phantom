!--------------------------------------------------------------------------!
! The Phantom Smoothed Particle Hydrodynamics code, by Daniel Price et al. !
! Copyright (c) 2007-2023 The Authors (see AUTHORS)                        !
! See LICENCE file for usage and distribution conditions                   !
! http://phantomsph.bitbucket.io/                                          !
!--------------------------------------------------------------------------!
module cooling_stamatellos
!
! Cooling method of Stamatellos et al. 2007
!
! :References: Stamatellos et al. 2007
!
! :Owner: Alison Young
!
! :Runtime parameters: None
!
! :Dependencies:
!
 
 implicit none
 public :: init_cooling_S07, cooling_S07
 real, public :: optable(260,1001,6)
 
 contains

   subroutine init_cooling_S07(ierr)
     use interp_optab,   only:read_optab
     integer, intent(out) :: ierr
     
     call read_optab(optable,ierr)
   end subroutine init_cooling_S07

!
! Do cooling calculation
!
   subroutine cooling_S07(rhoi,poti,ui,dudti,xi,yi,zi,tthermi,ueqi,umini,Tfloor)
     use physcon,  only:steboltz,pi,solarl
     use units,    only:umass,udist,unit_density,unit_ergg,utime
     use interp_optab, only:getopac_opdep,getintenerg_opdep
     real,intent(in) :: rhoi,poti,ui,dudti,xi,yi,zi,Tfloor
     real,intent(out) :: tthermi,ueqi,umini
     real            :: coldensi,kappaBari,kappaParti,Lstar,ri2
     real            :: Tirri,gammai,gmwi,Tmini,Ti,dudt_rad,Teqi
     real            :: tcool
     
!    Tfloor is from input parameters and is background heating
!    Add to stellar heating. Just assuming one star at (0,0,0) for now
     Lstar = 0.1 !in Lsun
     ri2 = xi*xi + yi*yi + zi*zi
     ri2 = ri2 *udist*udist
     Tirri = (Lstar*solarl/(4d0*pi*steboltz)/ri2)**0.25
     Tmini = Tfloor + Tirri
     
     coldensi = sqrt(abs(poti*rhoi)/4.d0/pi)
     coldensi = 0.368d0*coldensi ! n=2 in polytrope formalism Forgan+ 2009
     coldensi = coldensi*umass/udist/udist
     
! get opacities & Ti for ui
     call getopac_opdep(ui*unit_ergg,rhoi*unit_density,kappaBari,kappaParti,&
          Ti,gmwi,gammai,optable)
     tcool = (coldensi**2d0)*kappaBari +(1.d0/kappaParti)
     dudt_rad = 4.d0*steboltz*(Tmini**4.d0 - Ti**4.d0)/tcool/unit_ergg! code units
! calculate Teqi
     Teqi = dudti*(coldensi**2.d0*kappaBari + (1.d0/kappaParti))*unit_ergg/utime
     Teqi = Teqi/4.d0/steboltz
     Teqi = Teqi + Tmini**4.d0
     Teqi = Teqi**0.25d0
     if (Teqi < Tmini) then
        Teqi = Tmini
     endif
     call getintenerg_opdep(Teqi,rhoi*unit_density,ueqi,optable)
     ueqi = ueqi/unit_ergg
     call getintenerg_opdep(Tmini,rhoi*unit_density,umini,optable)
     umini = umini/unit_ergg
! calculate thermalization timescale
     tthermi = (ueqi - ui)/(dudti + dudt_rad)
! internal energy ui updated later in step     

   end subroutine cooling_S07
     
 end module cooling_stamatellos
