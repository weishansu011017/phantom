!--------------------------------------------------------------------------!
! The Phantom Smoothed Particle Hydrodynamics code, by Daniel Price et al. !
! Copyright (c) 2007-2023 The Authors (see AUTHORS)                        !
! See LICENCE file for usage and distribution conditions                   !
! http://phantomsph.bitbucket.io/                                          !
!--------------------------------------------------------------------------!
module moddump
!
! None
!
! :References: None
!
! :Owner: David Liptai
!
! :Runtime parameters:
!   - beta  : *penetration factor*
!   - ecc   : *eccentricity (1 for parabolic)*
!   - mh    : *mass of black hole (code units)*
!   - ms    : *mass of star       (code units)*
!   - phi   : *stellar rotation with respect to y-axis (in degrees)*
!   - r0    : *starting distance  (code units)*
!   - rs    : *radius of star     (code units)*
!   - theta : *stellar rotation with respect to x-axis (in degrees)*
!
! :Dependencies: centreofmass, dim, externalforces, infile_utils, io,
!   options, physcon, prompting, units
!
 implicit none

 real :: beta,   &  ! penetration factor
         mh,     &  ! BH mass
         ms,     &  ! stellar mass
         rs,     &  ! stellar radius
         theta,  &  ! stellar tilting along x
         phi,    &  ! stellar tilting along y
         r0,     &  ! starting distance
         ecc,    &  ! eccentricity
         spin       !spin of black hole


contains

subroutine modify_dump(npart,npartoftype,massoftype,xyzh,vxyzu)
 use centreofmass
 use externalforces, only:mass1
 use externalforces, only:accradius1,accradius1_hard
 use options,        only:iexternalforce,damp
 use dim,            only:gr
 use prompting,      only:prompt
 use physcon,        only:pi,solarm,solarr
 use units,          only:umass,udist,get_c_code
 use metric,         only:a
 use orbits_data,    only:isco_kerr
 use vectorutils,   only:rotatevec
 integer,  intent(inout) :: npart
 integer,  intent(inout) :: npartoftype(:)
 real,     intent(inout) :: massoftype(:)
 real,     intent(inout) :: xyzh(:,:),vxyzu(:,:)
 character(len=120)      :: filename
 integer                 :: i,ierr
 logical                 :: iexist
 real                    :: Lx,Ly,Lz,L,Lp,Ltot(3),L_sum(3)
 real                    :: rp,rt
 real                    :: x,y,z,vx,vy,vz
 real                    :: x0,y0,vx0,vy0,alpha,z0,vz0
 real                    :: c_light
 real                    :: unit_ltot(3),unit_L_sum(3),ltot_mag,L_mag
 real                    :: dot_value_angvec,angle_btw_vec,xyzstar(3),vxyzstar(3)
!
!-- Default runtime parameters
!
!
 beta  = 1.                  ! penetration factor
 Mh    = 1.e6*solarm/umass   ! BH mass
 Ms    = 1.  *solarm/umass   ! stellar mass
 rs    = 1.  *solarr/udist   ! stellar radius
 theta = 0.                  ! stellar tilting along x
 phi   = 0.                  ! stellar tilting along y
 ecc   = 1.                  ! eccentricity
 if (.not. gr) then
   spin = 0.
 else
   spin = 1. !upper limit on Sagitarrius A*'s spin is 0.1 (Fragione and Loeb 2020)'
 endif

 rt = (Mh/Ms)**(1./3.) * rs         ! tidal radius
 rp = rt/beta                       ! pericenter distance
 r0 = 10.*rt                        ! starting radius

 !
 !-- Read runtime parameters from tdeparams file
 !
 filename = 'tde'//'.tdeparams'                                ! moddump should really know about the output file prefix...
 inquire(file=filename,exist=iexist)
 if (iexist) call read_setupfile(filename,ierr)
 if (.not. iexist .or. ierr /= 0) then
    call write_setupfile(filename)
    print*,' Edit '//trim(filename)//' and rerun phantommoddump'
    stop
 endif
 rt = (Mh/Ms)**(1./3.) * rs         ! tidal radius
 rp = rt/beta                       ! pericenter distance
 theta=theta*pi/180.0
 !--Reset center of mass
 call reset_centreofmass(npart,xyzh,vxyzu)
 call get_angmom(ltot,npart,xyzh,vxyzu)
 if (ecc<1.) then
    print*, 'Eliptical orbit'
    alpha = acos((rt*(1.+ecc)/(r0*beta)-1.)/ecc)     ! starting angle anti-clockwise from positive x-axis
    x0    = -r0*cos(alpha)
    y0    = r0*sin(alpha)
    vx0   = sqrt(mh*beta/((1.+ecc)*rt)) * sin(alpha)
    vy0   = -sqrt(mh*beta/((1.+ecc)*rt)) * (cos(alpha)+ecc)
 elseif (abs(ecc-1.) < tiny(1.)) then
    print*, 'Parabolic orbit'
    y0    = -2.*rp + r0
    x0    = -sqrt(r0**2 - y0**2)
    z0    = 0.
    vx0   = sqrt(2*Mh/r0) * 2*rp / sqrt(4*rp**2 + x0**2)
    vy0   = sqrt(2*Mh/r0) * x0   / sqrt(4*rp**2 + x0**2)
    vz0   = 0.
    xyzstar = (/x0,y0,z0/)
    vxyzstar = (/vx0,vy0,vz0/)
 endif
 !--Set input file parameters
 if (.not. gr) then
    mass1          = Mh
    iexternalforce = 1
    damp           = 0.
    c_light        = get_c_code()
    accradius1     = (2*Mh)/(c_light**2) ! R_sch = 2*G*Mh/c**2
 endif
 !--Set input file parameters
 if (gr) then
    mass1          = Mh
    a              = spin
    call isco_kerr(a,mass1,accradius1)
    accradius1_hard = accradius1
 endif
 if (theta /= 0.) then
 !--Tilting the star around y axis, i.e., in xz place with angle theta
   call rotatevec(xyzstar,(/0.,1.,0./),theta)
   call rotatevec(vxyzstar,(/0.,1.,0./),theta)
   x0 = xyzstar(1)
   y0 = xyzstar(2)
   z0 = xyzstar(3)
   vx0 = vxyzstar(1)
   vy0 = vxyzstar(2)
   vz0 = vxyzstar(3)
 endif
 !--Tilting the star
 !--Putting star into orbit
 do i = 1, npart
    xyzh(1,i)  = xyzh(1,i)  + x0
    xyzh(2,i)  = xyzh(2,i)  + y0
    xyzh(3,i)  = xyzh(3,i)  + z0
    vxyzu(1,i) = vxyzu(1,i) + vx0
    vxyzu(2,i) = vxyzu(2,i) + vy0
    vxyzu(3,i) = vxyzu(3,i) + vz0
 enddo
 !check angular momentum after putting star on orbit
 call get_angmom(ltot,npart,xyzh,vxyzu)

 !find angular momentum of star on the orbit
 call angmom_star(xyzh,vxyzu,npart,L_sum,L_mag)

 unit_L_sum = L_sum(:)/L_mag
 ltot_mag = sqrt(dot_product(ltot,ltot))
 unit_ltot = ltot(:)/ltot_mag
 dot_value_angvec = dot_product(unit_L_sum,unit_ltot)
 angle_btw_vec = asin(dot_value_angvec)*57.2958 !convert to degrees
 theta=theta*180.0/pi
 write(*,'(a)') "======================================================================"
 write(*,'(a,Es12.5,a)') ' Pericenter distance = ',rp,' code units'
 write(*,'(a,Es12.5,a)') ' Tidal radius        = ',rt,' code units'
 write(*,'(a,Es12.5,a)') ' Radius of star      = ',rs,' code units'
 write(*,'(a,Es12.5,a)') ' Starting distance   = ',r0,' code units'
 write(*,'(a,Es12.5,a)') ' Stellar mass        = ',Ms,' code units'
 write(*,'(a,Es12.5,a)') ' Tilting along y axis     = ',theta,' degrees'
 !write(*,'(a,Es12.5,a)') ' Tilting along y     = ',phi,' degrees'
 write(*,'(a,Es12.5,a)') ' Eccentricity        = ',ecc
 if (gr) then
    write(*,'(a,Es12.5,a)') ' Spin of black hole "a"       = ',a
 endif

 write(*,'(a)') "======================================================================"

 return
end subroutine modify_dump

!
!---Read/write setup file--------------------------------------------------
!
subroutine write_setupfile(filename)
 use infile_utils, only:write_inopt
 use dim,          only:gr
 character(len=*), intent(in) :: filename
 integer, parameter :: iunit = 20

 print "(a)",' writing moddump params file '//trim(filename)
 open(unit=iunit,file=filename,status='replace',form='formatted')
 write(iunit,"(a)") '# parameters file for a TDE phantommodump'
 call write_inopt(beta,  'beta',  'penetration factor',                                  iunit)
 call write_inopt(mh,    'mh',    'mass of black hole (code units)',                     iunit)
 call write_inopt(ms,    'ms',    'mass of star       (code units)',                     iunit)
 call write_inopt(rs,    'rs',    'radius of star     (code units)',                     iunit)
 call write_inopt(theta, 'theta', 'stellar rotation with respect to y-axis (in degrees)',iunit)
 call write_inopt(r0,    'r0',    'starting distance  (code units)',                     iunit)
 call write_inopt(ecc,   'ecc',   'eccentricity (1 for parabolic)',                      iunit)
 if (gr) then
   call write_inopt(spin,   'a',   'spin of SMBH',                                       iunit)
 endif
 close(iunit)

end subroutine write_setupfile

subroutine read_setupfile(filename,ierr)
 use infile_utils, only:open_db_from_file,inopts,read_inopt,close_db
 use io,           only:error
 use dim,          only:gr
 character(len=*), intent(in)  :: filename
 integer,          intent(out) :: ierr
 integer, parameter :: iunit = 21
 integer :: nerr
 type(inopts), allocatable :: db(:)

 print "(a)",'reading setup options from '//trim(filename)
 nerr = 0
 ierr = 0
 call open_db_from_file(db,filename,iunit,ierr)
 call read_inopt(beta,  'beta',  db,min=0.,errcount=nerr)
 call read_inopt(mh,    'mh',    db,min=0.,errcount=nerr)
 call read_inopt(ms,    'ms',    db,min=0.,errcount=nerr)
 call read_inopt(rs,    'rs',    db,min=0.,errcount=nerr)
 call read_inopt(theta, 'theta', db,min=0.,errcount=nerr)
 !call read_inopt(phi,   'phi',   db,min=0.,errcount=nerr)
 call read_inopt(r0,    'r0',    db,min=0.,errcount=nerr)
 call read_inopt(ecc,   'ecc',   db,min=0.,max=1.,errcount=nerr)
 if (gr) then
   call read_inopt(spin, 'a',    db,min=-1.,max=1.,errcount=nerr)
 endif

 call close_db(db)
 if (nerr > 0) then
    print "(1x,i2,a)",nerr,' error(s) during read of setup file: re-writing...'
    ierr = nerr
 endif

end subroutine read_setupfile

subroutine get_angmom(ltot,npart,xyzh,vxyzu)
 real, intent(out)   :: ltot(3)
 integer, intent(in) :: npart
 real, intent(in)    :: xyzh(:,:), vxyzu(:,:)
 integer :: i
 real    :: L

 ltot = 0.
 do i=1,npart
    ltot(1) = ltot(1)+xyzh(2,i)*vxyzu(3,i)-xyzh(3,i)*vxyzu(2,i)
    ltot(2) = ltot(2)+xyzh(3,i)*vxyzu(1,i)-xyzh(1,i)*vxyzu(3,i)
    ltot(3) = ltot(3)+xyzh(1,i)*vxyzu(2,i)-xyzh(2,i)*vxyzu(1,i)
 enddo

 L = sqrt(dot_product(ltot,ltot))

 print*,''
 print*,'Checking angular momentum orientation and magnitude...'
 print*,'Angular momentum is L = (',ltot(1),ltot(2),ltot(3),')'
 print*,'Angular momentum modulus is |L| = ',L
 print*,''

end subroutine get_angmom
