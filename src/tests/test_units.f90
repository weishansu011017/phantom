!--------------------------------------------------------------------------!
! The Phantom Smoothed Particle Hydrodynamics code, by Daniel Price et al. !
! Copyright (c) 2007-2025 The Authors (see AUTHORS)                        !
! See LICENCE file for usage and distribution conditions                   !
! http://phantomsph.github.io/                                             !
!--------------------------------------------------------------------------!
module testunits
!
! Unit test for routines in the units module
!
! :References:
!
! :Owner: Daniel Price
!
! :Runtime parameters: None
!
! :Dependencies: units
!
 use testutils, only:checkval,update_test_scores
 use io,        only:id,master
 implicit none
 public :: test_units

 private

contains

!--------------------------------------------
!+
!  Various tests of the units module
!+
!--------------------------------------------
subroutine test_units(ntests,npass)
 integer, intent(inout) :: ntests,npass

 if (id==master) write(*,"(/,a)") '--> TESTING UNITS MODULE'
 
 call test_unit_extraction(ntests,npass)
 call test_unit_conversions(ntests,npass)

 if (id==master) write(*,"(/,a)") '<-- UNITS TEST COMPLETE'

end subroutine test_units

!--------------------------------------------
!+
!  test of unit extraction routine
!+
!--------------------------------------------
subroutine test_unit_extraction(ntests,npass)
 use units, only:get_unit_multiplier
 integer, intent(inout) :: ntests,npass
 real(kind=8) :: val
 character(len=30) :: string, unit_string
 integer :: ierr, nfailed(20)
 real(kind=8), parameter :: tol = 1.e-12

 if (id==master) write(*,"(/,a)") '--> testing unit extraction'
 nfailed = 0

 ! Test 1: Simple number with units
 string = '1.0 msun'
 call get_unit_multiplier(string, unit_string, val, ierr)
 call checkval(val, 1.0d0, tol, nfailed(1), 'value from '//trim(string))
 call checkval(trim(unit_string),'msun',nfailed(2), 'units from '//trim(string))
 call checkval(ierr,0,0,nfailed(3),'error code from '//trim(string))

 ! Test 2: Scientific notation with units
 string = '1.23e-4 au'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,1.23e-4,tol,nfailed(4),'value from '//trim(string))
 call checkval(trim(unit_string),'au',nfailed(5),'units from '//trim(string))

 ! Test 3: Asterisk separator
 string = '2.5*rsun'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,2.5d0,tol,nfailed(6),'value from '//trim(string))
 call checkval(trim(unit_string),'rsun',nfailed(7),'units from '//trim(string))

 ! Test 4: Complex units with spaces
 string = '2.7 g/cm^3'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,2.7d0,tol,nfailed(8),'value from '//trim(string))
 call checkval(trim(unit_string), 'g/cm^3',nfailed(9),'units from '//trim(string))

 ! Test 5: Just units (no number)
 string = 'msun'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,1.0d0,tol,nfailed(10), 'value from '//trim(string))
 call checkval(trim(unit_string),'msun',nfailed(11), 'units from '//trim(string))

 ! Test 6: Zero with units
 string = '0.0 lsun'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,0.0d0,tol,nfailed(12),'value from '//trim(string))
 call checkval(trim(unit_string),'lsun',nfailed(13),'units from '//trim(string))

 ! Test 7: Negative number with units
 string = '-1.5 km/s'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,-1.5d0,tol,nfailed(14),'value from '//trim(string))
 call checkval(trim(unit_string),'km/s',nfailed(15),'units from '//trim(string))

 ! Test 8: Number without units (should error)
 string = '1.0'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(ierr,0,0,nfailed(16),'error code from '//trim(string))

 ! Test 9: Empty string
 string = ''
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,1.0d0,tol,nfailed(17),'value from empty string')
 call checkval(len_trim(unit_string),0,0,nfailed(18),'units length from empty string')

 ! Test 10: Multiple spaces between number and units
 string = '3.14    parsec'
 call get_unit_multiplier(string,unit_string,val,ierr)
 call checkval(val,3.14d0,tol,nfailed(19),'value from '//trim(string))
 call checkval(trim(unit_string),'parsec',nfailed(20),'units from '//trim(string))

 ! Update test scores
 call update_test_scores(ntests, nfailed, npass)

 if (id==master) write(*,"(/,a)") '<-- unit extraction tests complete'

end subroutine test_unit_extraction

!--------------------------------------------
!+
!  test of unit conversion roundtrip
!+
!--------------------------------------------
subroutine test_unit_conversions(ntests,npass)
 use units,   only:in_units,in_code_units,set_units
 use physcon, only:au,solarm
 integer, intent(inout) :: ntests,npass
 integer :: i,nfailed(60)  ! Increased for more tests
 real, parameter :: tol = epsilon(0.)
 real :: val_code,val_roundtrip
 character(len=30) :: valstring
 integer :: ierr

 type test_case
    real :: val_cgs
    character(len=30) :: unit_string
 end type test_case

 type(test_case), parameter :: tests(30) = [ &
    ! mass units
    test_case(1.0,     'msun'),      &
    test_case(317.8,   'mjup'),      &
    test_case(0.001,   'mearth'),    &
    test_case(1.0e30,  'g'),         &
    ! length units
    test_case(2.5,     'au'),        &
    test_case(6.0,     'rsun'),      &
    test_case(30.0,    'rjup'),      &
    test_case(1.0e5,   'km'),        &
    test_case(0.5,     'pc'),        &
    test_case(312.4,   'kpc'),       &
    ! time units
    test_case(365.25,  'days'),      &
    test_case(2.0,     'yr'),        &
    test_case(3.0e6,   'yr'),        & ! 1 Myr
    test_case(24.0,    'hr'),        &
    test_case(3600.0,  'sec'),       &
    ! velocity units
    test_case(0.23,    'km/s'),      &
    test_case(30.0,    'km/s'),      &
    test_case(0.065,   'c'),         &
    ! density units
    test_case(-3.14,   'g/cm^3'),    &
    test_case(1.0e-24, 'g/cm^3'),    &
    test_case(1.67,    'kg/m^3'),    &
    ! mass flow units
    test_case(0.5e-6,  'msun/yr'),   &
    test_case(0.2,     'g/s'),       &
    ! luminosity units
    test_case(10.7,    'lsun'),      &
    test_case(1.0e36,  'erg/s'),     &
    ! edge cases
    test_case(0.0,     'msun'),      & ! Zero mass
    test_case(1.0e-20, 'g/cm^3'),    & ! Very small density
    test_case(1.0e10,  'km/s'),      & ! Very high velocity
    test_case(-100.0,  'lsun'),      & ! Negative luminosity
    test_case(1.0e-15, 'mearth')     & ! Very small mass
    ]

 if (id==master) write(*,"(/,a)") '--> testing unit conversion roundtrip'
 nfailed = 0

 ! Set some non-trivial units to test with
 call set_units(dist=au,mass=solarm,G=1.d0)

 do i = 1, size(tests)
    write(valstring,'(1pg12.5)') tests(i)%val_cgs
    valstring = trim(adjustl(valstring))//' '//trim(tests(i)%unit_string)

    ! Convert to code units
    val_code = in_code_units(trim(valstring), ierr)

    ! Convert from code units to physical units
    val_roundtrip = real(in_units(val_code,trim(tests(i)%unit_string)))

    ! Check roundtrip conversion
    call checkval(val_roundtrip,tests(i)%val_cgs,tol,nfailed(2*i-1),trim(valstring))

    ! Check error code
    call checkval(ierr,0,0,nfailed(2*i),'error code')
 enddo

 ! Update test scores
 call update_test_scores(ntests, nfailed, npass)

 if (id==master) write(*,"(/,a)") '<-- unit conversion roundtrip tests complete'

end subroutine test_unit_conversions

end module testunits
