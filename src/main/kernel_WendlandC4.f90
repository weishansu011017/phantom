!--------------------------------------------------------------------------!
! The Phantom Smoothed Particle Hydrodynamics code, by Daniel Price et al. !
! Copyright (c) 2007-2025 The Authors (see AUTHORS)                        !
! See LICENCE file for usage and distribution conditions                   !
! http://phantomsph.github.io/                                             !
!--------------------------------------------------------------------------!
module kernel
!
! This module implements the Wendland 2/3D C^4 kernel
!   DO NOT EDIT - auto-generated by kernels.py
!
! :References: None
!
! :Owner: Daniel Price
!
! :Runtime parameters: None
!
! :Dependencies: physcon
!
 use physcon, only:pi
 implicit none
 character(len=17), public :: kernelname = 'Wendland 2/3D C^4'
 real, parameter, public  :: radkern  = 2.
 real, parameter, public  :: radkern2 = 4.
 real, parameter, public  :: cnormk = 495./(256.*pi)
 real, parameter, public  :: wab0 = 1., gradh0 = -3.*wab0
 real, parameter, public  :: dphidh0 = 55./32.
 real, parameter, public  :: cnormk_drag = 6435./(2048.*pi)
 real, parameter, public  :: hfact_default = 1.5
 real, parameter, public  :: av_factor = 35./36.

contains

pure subroutine get_kernel(q2,q,wkern,grkern)
 real, intent(in)  :: q2,q
 real, intent(out) :: wkern,grkern

 !--Wendland 2/3D C^4
 if (q < 2.) then
    wkern  = (1 - q/2.)**6*(35.*q2/12. + 3.*q + 1.)
    grkern = (1 - q/2.)**6*(35.*q/6. + 3.) - 3.*(1. - q/2.)**5*(35.*q2/12. + 3.*q + &
                 1.)
 else
    wkern  = 0.
    grkern = 0.
 endif

end subroutine get_kernel

pure elemental real function wkern(q2,q)
 real, intent(in) :: q2,q

 if (q < 2.) then
    wkern = (1 - q/2.)**6*(35.*q2/12. + 3.*q + 1.)
 else
    wkern = 0.
 endif

end function wkern

pure elemental real function grkern(q2,q)
 real, intent(in) :: q2,q

 if (q < 2.) then
    grkern = (1 - q/2.)**6*(35.*q/6. + 3.) - 3.*(1. - q/2.)**5*(35.*q2/12. + 3.*q + &
                 1.)
 else
    grkern = 0.
 endif

end function grkern

pure subroutine get_kernel_grav1(q2,q,wkern,grkern,dphidh)
 real, intent(in)  :: q2,q
 real, intent(out) :: wkern,grkern,dphidh
 real :: q4, q6, q8

 if (q < 2.) then
    q4 = q2*q2
    q6 = q4*q2
    q8 = q6*q2
    wkern  = (1 - q/2.)**6*(35.*q2/12. + 3.*q + 1.)
    grkern = (1 - q/2.)**6*(35.*q/6. + 3.) - 3.*(1. - q/2.)**5*(35.*q2/12. + 3.*q + &
                 1.)
    dphidh = -1155.*q6*q4/32768. + 55.*q8*q/128. - 17325.*q8/8192. + 165.*q6*q/32. - &
                 5775.*q6/1024. + 1155.*q4/256. - 495.*q2/128. + 55./32.
 else
    wkern  = 0.
    grkern = 0.
    dphidh = 0.
 endif

end subroutine get_kernel_grav1

pure subroutine kernel_softening(q2,q,potensoft,fsoft)
 real, intent(in)  :: q2,q
 real, intent(out) :: potensoft,fsoft
 real :: q4, q6, q8

 if (q < 2.) then
    q4 = q2*q2
    q6 = q4*q2
    q8 = q6*q2
    potensoft = 105.*q6*q4/32768. - 11.*q8*q/256. + 1925.*q8/8192. - 165.*q6*q/256. + &
                 825.*q6/1024. - 231.*q4/256. + 165.*q2/128. - 55./32.
    fsoft     = q*(525.*q8 - 6336.*q6*q + 30800.*q6 - 73920.*q4*q + 79200.*q4 - &
                 59136.*q2 + 42240.)/16384.
 else
    potensoft = -1./q
    fsoft     = 1./q2
 endif

end subroutine kernel_softening

!------------------------------------------
! gradient acceleration kernel needed for
! use in Forward symplectic integrator
!------------------------------------------
pure subroutine kernel_grad_soft(q2,q,gsoft)
 real, intent(in)  :: q2,q
 real, intent(out) :: gsoft
 real :: q4, q6

 if (q < 2.) then
    q4 = q2*q2
    q6 = q4*q2
    gsoft = 3.*q2*q*(175.*q6 - 1848.*q4*q + 7700.*q4 - 15400.*q2*q + 13200.*q2 - &
                 4928.)/2048.
 else
    gsoft = -3./q2
 endif

end subroutine kernel_grad_soft

!------------------------------------------
! double-humped version of the kernel for
! use in drag force calculations
!------------------------------------------
pure elemental real function wkern_drag(q2,q)
 real, intent(in) :: q2,q

 !--double hump Wendland 2/3D C^4 kernel
 if (q < 2.) then
    wkern_drag = q2*(1. - q/2.)**6*(35.*q2/12. + 3.*q + 1.)
 else
    wkern_drag = 0.
 endif

end function wkern_drag

end module kernel
