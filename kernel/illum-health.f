c                         *                          *                       iii                   *     *
c                                                                           iiiii
c  IIIIII    lLLLL    *    lLLLL         UUU    UUU      MMMMM      MMMMM    iii        NNNN     NN          AAAA
c   IIII     LLLL          LLLL   *     UUU      UUU     MMMMMMM  MMMMMMM          *    NNNNN    NN        AAAaaAAA
c   IIII     LLLL          LLLL        UUU *      UUU    MMM MMMMMMMM MMM    iii        NNNNNN   NN       AAA    AAA
c   IIII     LLLL   *      LLLL        UUU        UUU    MMM *        MMM  iii          NNN  NNN NN     AAAAAAAAAAAAAA
c   IIII     LLLl          LLLl        UUUu      uUUU    MMM          MMM  iiii    ii   NNN   NNNNN    AAAa        aAAA
c   IIII    LLLLLLLLLL    LLLLLLLLLL    UUUUUuuUUUUU     MMM          MMM   iiiiiiiii   NNN    NNNN   aAAA    *     AAAa
c  IIIIII   LLLLLLLLLLL   LLLLLLLLLLL     UUUUUUUU      mMMMm        mMMMm   iiiiiii   nNNNn    NNNn  aAAA          AAAa
c
c **********************************************************************************************************************
c ** Illumina - health in Fortran 77                                                                                  **
c ** Programmers in decreasing order of contribution  :                                                               **
c **                            Martin Aube                                                                           **
c **                                                                                                                  **
c ** Illumina can be downloaded via:                                                                                  **
c **    git clone https://github.com/aubema/illumina.git                                                              **
c **    git checkout illum-health                                                                                     **
c ** To compile:                                                                                                      **
c **    cd git/illumina                                                                                               **
c **    bash bin/makeILLUMINA                                                                                             **
c **                                                                                                                  **
c **  Current version features/limitations :                                                                          **
c **                                                                                                                  **
c **    - Lambertian reflexion on the ground                                                                          **
c **    - Terrain slope considered (apparent surface and shadows)                                                     **
c **    - Angular photometry of a lamp is considered assuming ies file orientation aligned with nearest street        **
c **    - Sub-grid obstacles considered (with the mean free path of light toward ground, mean obstacle height, and    **
c **      obstacles transparency (filling factor) The typical mean free path is the distance between two streets      **
c **    - Accounting for heterogeneity luminaires number, luminaires heights, luminaire spectrum,                     **
c **      angular photometry, obstacle properties                                                                     **
c **    - Wavelength dependant                                                                                        **
c **    - Consider reflectance of streets and building facades and other.                                             **
c **    - Support direct observation of a source                                                                      **
c **    - Direct observation of the ground and facades are implemented                                                **
c **                                                                                                                  **
c **********************************************************************************************************************
c
c  Copyright (C) 2022 Martin Aube PhD
c
c  This program is free software: you can redistribute it and/or modify
c  it under the terms of the GNU General Public License as published by
c  the Free Software Foundation, either version 3 of the License, or
c  (at your option) any later version.
c
c  This program is distributed in the hope that it will be useful,
c  but WITHOUT ANY WARRANTY; without even the implied warranty of
c  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c  GNU General Public License for more details.
c
c  You should have received a copy of the GNU General Public License
c  along with this program.  If not, see <http://www.gnu.org/licenses/>.
c
c  Contact: martin.aube@cegepsherbrooke.qc.ca
c
c
c
      program illumina                                                    ! Beginning
      implicit none
c
c=======================================================================
c     Variables declaration
c=======================================================================
c
      integer width,nzon                                                  ! Matrix dimension in Length/width and height
      parameter (width=1024,nzon=36)
      integer iun,ideux
      real pi,pix4
      integer verbose                                                     ! verbose = 1 to have more print out, 0 for silent
      parameter (pi=3.141592654)
      parameter (pix4=4.*pi)
      character*72 mnaf                                                   ! Terrain elevation file
      character*72 outfile                                                ! Results file
      character*72 basenm                                                 ! Base name of files
      integer lenbase                                                     ! Length of the Base name of the experiment
      real lambda,pressi,drefle(width,width)                              ! Wavelength (nanometer), atmospheric pressure (kPa), mean free path to the ground (meter).
      real reflsiz                                                        ! Size of the reflecting surface
      integer ntype                                                       ! Number of light source types or zones considered
      real largx                                                          ! Width (x axis) of the modeling domain (meter)
      real largy                                                          ! Length (y axis) of the modeling domain (meter)
      integer nbx,nby                                                     ! Number of pixels in the modeling domain
      real val2d(width,width)                                             ! Temporary input array 2d
      real altsol(width,width)                                            ! Ground elevation (meter)
      real reflec(width,width)                                            ! reflectance 
      real srefl,brefl,orefl                                              ! Street reflectance , Building facades reflectance , Other reflectance
      integer stype                                                       ! Source type or zone index
      character*72 pafile,lufile,alfile,ohfile,odfile,offile              ! Files related to light sources and obstacles (photometric function of the sources (sr-1), flux (W), height (m), obstacles c                                 ! height (m), obstacle distance (m), obstacle filling factor (0-1).
      real lamplu(width,width,nzon)                                       ! Source fluxes
      real lampal(width,width)                                            ! Height of the light sources relative to the ground (meter)
      real pval(91,181,nzon),pvalto,pvalno(91,181,nzon)                   ! Values of the angular photometry functions (unnormalized, integral, normalized)
      real dtheta                                                         ! Angle increment of the photometric function of the sources
      real dx,dy,dxp,dyp                                                  ! Width of the voxel (meter)
      integer boxx,boxy                                                   ! reflection window size (pixels)
      real inclix(width,width)                                            ! tilt of the ground pixel along x (radian)
      real incliy(width,width)                                            ! tilt of the ground pixel along y (radian)
      integer x_obs,y_obs                                                 ! Position of the observer (INTEGER)
      real rx_obs,ry_obs
      real z_o                                                            ! observer height relative to the ground (meter)
      real z_obs                                                          ! Height of the observer (meter) to the vertical grid scale
      integer ncible,icible                                               ! Number of line of sight voxels, number loops over the voxels
      integer x_s,y_s,x_sr,y_sr                                           ! Positions of the source, the reflecting surface
      real z_s,z_sr,z_dif                                                 ! Heights of the source, the reflecting surface, and the scattering voxel (metre).
      real rx_s,ry_s,rx_sr,ry_sr
      real angzen,ouvang                                                  ! Zenithal angle between two voxels (radians) and opening angle of the solid angle in degrees.
      integer anglez                                                      ! Emitting zenithal angle from the luminaire.
      real P_dir,P_indir                                                  ! photometric function of the light sources (direct,indirect,scattered)
      real*8 xc,yc,zc,xn,yn,zn                                            ! Position (meter) of the elements (starting point, final point) for the calculation of the solid angle.
      real*8 r1x,r1y,r1z,r2x,r2y,r2z,r3x,r3y,r3z,r4x,r4y,r4z              ! Components of the vectors used in the solid angle calculation routine.
      real omega                                                          ! Solid angles
      real ftocap                                                         ! Total flux reaching the observer voxel
      real haut                                                           ! Haut (negative indicate that the surface is lighted from inside the ground. I.e. not considered in the calculation
      real epsilx,epsily                                                  ! tilt of the ground pixel
      real flrefl                                                         ! flux reaching a reflecting surface (watts).
      real irefl,irefl1                                                   ! intensity leaving a reflecting surface toward the line of sight voxel.
      real dis_obs                                                        ! Distance between the line of sight and the observer.
      real omefov                                                         ! Solid angle of the spectrometer slit.
      real angvis,azim                                                    ! viewing angles of the sensor.
c                                                                         ! Useful for the calculation of the lambertian reflectance.
      real nbang                                                          ! for the averaging of the photometric function
      real obsH(width,width),angmin                                       ! averaged height of the sub-grid obstacles, minimum angle under wich
c                                                                         ! a light ray cannot propagate because it is blocked by a sub-grid obstable
      real ofill(width,width)                                             ! fill factor giving the probability to hit an obstacle when pointing in its direction real 0-1
      integer naz,na
      real lpluto(width,width)                                            ! total luminosity of the ground cell for all lamps
      character*3 lampno                                                  ! lamp number string
      integer imin(nzon),imax(nzon),jmin(nzon),jmax(nzon)                 ! x and y limits containing a type of lamp
      real angazi                                                         ! azimuth angle between two points in rad, max dist for the horizon determination
      real latitu                                                         ! approximate latitude of the domain center
      integer xsrmi,xsrma,ysrmi,ysrma                                     ! limits of the loop valeur for the reflecting surfaces
      real totlu(nzon)                                                    ! total flux of a source type
      real ff,ff2,hh                                                      ! temporary obstacle filling factor and horizon blocking factor
      real distd                                                          ! distance to compute the scattering probability
      real volu                                                           ! volume of a voxel
      real scal                                                           ! stepping along the line of sight
      real scalo                                                          ! previous value of scal
      real siz                                                            ! resolution of the 2nd scat grid in meter
      real angvi1,angaz1,angze1                                           ! viewing angles in radian
      real ix,iy,iz                                                       ! base vector of the viewing (length=1)
      real azcl1,azcl2                                                    ! zenith angle from the (source, refl surface, or scattering voxel) to line of path and observer to line p.
      real dh,dho                                                         ! distance of the horizon limit
      integer n2nd                                                        ! desired number of voxel in the calculation of the 2nd scattering
      integer step                                                        ! skiping 2nd scat on 1 dim
      real omemax                                                         ! max solid angle allowed
      real diamobj                                                        ! instrument objective diameter
      integer i,j,k,id,jd
      real tranam,tranaa,tranal                                           ! TOA atmospheric transmittancess of a path (molecular, aerosol, layer)
      real transa,transl,transm
      real zhoriz                                                         ! zenith angle of the horizon
      real direct                                                         ! direct radiance from sources on a surface normal to the line of sight (no scattering)
      real rdirect                                                        ! direct radiance from a reflecting surface on a surface normal to the line of sight (no scattering)
      real irdirect                                                       ! direct irradiance from sources on a surface normal to the line of sight (no scattering)
      real irrdirect                                                      ! direct irradiance from a reflecting surface on a surface normal to the line of sight (no scattering)
      real dang                                                           ! Angle between the line of sight and the direction of a source
      real dzen                                                           ! zenith angle of the source-observer line
      real ddir_obs                                                       ! distance between the source and the observer
      real rx,ry,rz                                                       ! driving vector for the calculation of the projection angle for direct radiance. It is 20km long
      real dfov                                                           ! field of view in degrees for the calculation of the direct radiance this number will be a kind of smoothing effect. The angular grid resolution to create a direct radiance panorama should be finer than that number
      real Fo                                                             ! flux correction factor for obstacles
      integer gndty(width,width)                                          ! ground type flag  0=observer, 1=building facade, 2=street, 3=other
      character*72 gifile                                                 ! name of the ground type flag file
      real dh0,dhmax                                                      ! horizontal distance along the line of sight and maximum distance before beeing blocked by topography
      character*72 layfile                                                ! filename of the optical properties of the particle layer
      real layaod                                                         ! 500 nm aod of the particle layer
      real layalp                                                         ! spectral exponent of the aod for the particle layer
      real hlay                                                           ! exponential vertical scale height of the particle layer
      real haer                                                           ! exponential vertical scale height of the background aerosol layer
      real bandw                                                          ! bandwidth of the spectral bin
      real tabs                                                           ! TOA transmittance related to molecule absorption
      integer obsobs                                                      ! flag to activate the direct light obstacle blocking aroud the observer.
      verbose=1                                                           ! Very little printout=0, Many printout = 1, even more=2
      diamobj=1.                                                          ! A dummy value for the diameter of the objective of the instrument used by the observer.
      volu=0.
      un=1.
      ff=0.
      ff2=0.
      step=1
      ncible=1024
      if (verbose.ge.1) then
        print*,'Starting ILLUMINA computations...'
      endif
c reading of the fichier d'entree (illumina.in)
      print*,'Reading illum-health.in input file'
      open(unit=1,file='illum-health.in',status='old')
        read(1,*)
        read(1,*) basenm
        read(1,*) dx,dy
        read(1,*) layfile, layaod, layalp, hlay
        read(1,*) taua,alpha,haer
        read(1,*) lambda,bandw
        read(1,*) srefl,brefl,orefl
        read(1,*) pressi
        read(1,*) ntype
        read(1,*) z_o             IL FAUT FAIRE UNE BOUCLE SUR TOUT LE DOMAINE ET CALCULER LES POS OBSERVATEUR QUAND gndty()=0
        read(1,*) obsobs
        read(1,*) angvis,azim
        read(1,*) dfov
        read(1,*) reflsiz         IL FAUT REMPLACER CETTE VARIABLE PAR drefl()   
      close(1)
      if (angvis.gt.90.) then
         print*,'Error: elevation angle larger than 90 deg'
         stop
      endif
      if (angvis.lt.-90.) then
         print*,'Error: elevation angle smaller than -90 deg'
         stop
      endif
c conversion of the geographical viewing angles toward the cartesian
c angle we assume that the angle in the file illumina.in
c is consistent with the geographical definition
c geographical, azim=0 toward north, 90 toward east, 180 toward south
c etc
c cartesian, azim=0 toward east, 90 toward north, 180 toward west etc
      azim=90.-azim
      if (azim.lt.0.) azim=azim+360.
      if (azim.ge.360.) azim=azim-360.
      angvi1 = (pi*angvis)/180.
      angze1 = pi/2.-angvi1
      angaz1 = (pi*azim)/180.
      ix = ( sin((pi/2.)-angvi1) ) * (cos(angaz1))                        ! viewing vector components
      iy = ( sin((pi/2.)-angvi1) ) * (sin(angaz1))
      iz = (sin(angvi1))
      dfov=(dfov*pi/180.)/2.
      siz=2500.
      scal=19.
      scalo=scal
      boxx=nint(reflsiz/dx)                                               ! Number of column to consider left/right of the source for the reflection.
      boxy=nint(reflsiz/dy)                                               ! Number of column to consider up/down of the source for the reflection.
c omemax: exclude calculations too close (<10m) this is a sustended angle of 1 deg.
c the calculated flux is highly sensitive to that number for a very high
c pixel resolution (a few 10th of meters). We assume anyway that somebody
c observing the sky will never lies closer than that distance to a
c light fixture. This number is however somehow subjective and that means
c that the value of sky brightness near sources will be affected by this
c choice
      omemax=1./((10.)**2.)
      if (verbose.gt.0) then
        print*,'Pixel size = ',dx,' x ',dy
        print*,'Maximum radius for reflection = ',reflsiz
      endif
c computing the actual AOD at the wavelength lambda
      if (verbose.ge.1) print*,'500nm AOD=',taua,'500nm angstrom coeff.=
     +',alpha
      taua=taua*(lambda/500.)**(-1.*alpha)
      layaod=layaod*(lambda/500.)**(-1.*layalp)
c  determine the Length of basenm
      lenbase=index(basenm,' ')-1
      mnaf=basenm(1:lenbase)//'_topogra.bin'                              ! determine the names of input and output files
      outfile=basenm(1:lenbase)//'.out'
c opening output file
      open(unit=2,file=outfile,status='unknown')
        write(2,*) "ILLUMINA version __version__"
        write(2,*) 'FILE USED:'
        write(2,*) mnaf
        print*,'Wavelength (nm):',lambda,
     +       ' Aerosol optical depth:',taua
        write(2,*) 'Wavelength (nm):',lambda,
     +       ' Aerosol optical depth:',taua
        write(2,*) 'Observer position (x,y,z)',x_obs,y_obs,z_o
        print*,'Observer position (x,y,z)',x_obs,y_obs,z_o
        write(2,*) 'Elevation angle:',angvis,' azim angle (counterclockwise
     +from east)',azim
        print*,'Elevation angle:',angvis,' azim angle (counterclockwise
     +from east)',azim
c Initialisation of the arrays and variables
        if (verbose.ge.1) print*,'Initializing variables...'
        iun=0
        ideux=1
        do i=1,width
          do j=1,width
            val2d(i,j)=0.
            altsol(i,j)=0.
            obsH(i,j)=0.
            gndty(i,j)=0
            ofill(i,j)=0.
            inclix(i,j)=0.
            incliy(i,j)=0.
            lpluto(i,j)=0.
            flcld(i,j)=0.
            do k=1,nzon
              lamplu(i,j,k)=0.
              lampal(i,j)=0.
            enddo
          enddo
        enddo
          do j=1,nzon
            pval(i,j)=0.
            pvalno(i,j)=0.
          enddo
        enddo
        angmin=0.
        flrefl=0.
        irefl=0.
        irefl1=0.
        fccld=0.
        fctcld=0.
        omefov=0.
        hh=1.
c reading of the environment variables
c reading of the elevation file
        call twodin(nbx,nby,mnaf,altsol)

c reading of the values of P(theta), height, luminosities and positions
c of the sources, obstacle height and distance
        ohfile=basenm(1:lenbase)//'_obsth.bin'
        odfile=basenm(1:lenbase)//'_obstd.bin'
        alfile=basenm(1:lenbase)//'_altlp.bin'                            ! setting the file name of height of the sources lumineuse.
        offile=basenm(1:lenbase)//'_obstf.bin'
        gifile='groundtype.bin'
        dtheta=.017453293                                                 ! one degree
c reading lamp heights
        call twodin(nbx,nby,alfile,val2d)
        do i=1,nbx                                                        ! beginning of the loop over all cells along x.
          do j=1,nby                                                      ! beginning of the loop over all cells along y.
            lampal(i,j)=val2d(i,j)                                        ! filling of the array for the lamp stype
          enddo                                                           ! end of the loop over all cells along y.
        enddo                                                             ! end of the loop over all cells along x.
c reading subgrid obstacles average height
        call twodin(nbx,nby,ohfile,val2d)
        do i=1,nbx                                                        ! beginning of the loop over all cells along x.
          do j=1,nby                                                      ! beginning of the loop over all cells along y.
            obsH(i,j)=val2d(i,j)                                          ! filling of the array
          enddo                                                           ! end of the loop over all cells along y.
        enddo
c reading subgrid obstacles average distance
        call twodin(nbx,nby,odfile,val2d)
        do i=1,nbx                                                        ! beginning of the loop over all cells along x.
          do j=1,nby                                                      ! beginning of the loop over all cells along y.
            drefle(i,j)=val2d(i,j)/2.
            if (drefle(i,j).eq.0.) drefle(i,j)=dx                         ! when outside a zone, block to the size of the cell (typically 1km)
          enddo                                                           ! end of the loop over all cells along y.
        enddo
c reading subgrid obstacles filling factor
        call twodin(nbx,nby,offile,val2d)
        do i=1,nbx                                                        ! beginning of the loop over all cells along x.
          do j=1,nby                                                      ! beginning of the loop over all cells along y.
            ofill(i,j)=val2d(i,j)                                         ! Filling of the array 0-1
          enddo                                                           ! end of the loop over all cells along y.
        enddo
c reading ground type flag
        call twodin(nbx,nby,gifile,val2d)
        do i=1,nbx                                                        ! beginning of the loop over all cells along x.
          do j=1,nby                                                      ! beginning of the loop over all cells along y.
            gndty(i,j)=nint(val2d(i,j))                                   ! ground type flag flag array 0 or 1
          enddo                                                           ! end of the loop over all cells along y.
        enddo
c Some preliminary tasks
        do stype=1,ntype                                                  ! beginning of the loop 1 for the nzon types of sources.
          imin(stype)=nbx
          jmin(stype)=nby
          imax(stype)=1
          jmax(stype)=1
          pvalto=0.
          write(lampno, '(I3.3)' ) stype                                  ! support of nzon different sources (3 digits)
          pafile=basenm(1:lenbase)//'_fctem_'//lampno//'.dat'             ! setting the file name of angular photometry.
          lufile=basenm(1:lenbase)//'_lumlp_'//lampno//'.bin'             ! setting the file name of the luminosite of the cases.
c reading photometry files
          open(UNIT=1, FILE=pafile,status='OLD')                          ! opening file pa#.dat, angular photometry.
            do i=1,181                                                    ! beginning of the loop for the 181 data points
              read(1,*) pval(i,stype)                                     ! reading of the data in the array pval.
              pvalto=pvalto+pval(i,stype)*2.*pi*                          ! Sum of the values of the  photometric function
     a        sin(real(i-1)*dtheta)*dtheta                                ! (pvaleur x 2pi x sin theta x dtheta) (ou theta egale (i-1) x 1 degrees).
            enddo                                                         ! end of the loop over the 181 donnees of the fichier pa#.dat.
          close(1)                                                        ! closing file pa#.dat, angular photometry.
          do i=1,181
            if (pvalto.ne.0.) pvalno(i,stype)=pval(i,stype)/pvalto        ! Normalisation of the photometric function.
          enddo
c reading luminosity files
          call twodin(nbx,nby,lufile,val2d)
          do i=1,nbx                                                      ! beginning of the loop over all cells along x.
            do j=1,nby                                                    ! beginning of the loop over all cells along y.
              if (val2d(i,j).lt.0.) then                                  ! searching of negative fluxes
                print*,'***Negative lamp flux!, stopping execution'
                stop
              endif
            enddo                                                         ! end of the loop over all cells along y.
          enddo
          do i=1,nbx                                                      ! searching of the smallest rectangle containing the zone
            do j=1,nby                                                    ! of non-null luminosity to speedup the calculation
              if (val2d(i,j).ne.0.) then
                if (i-1.lt.imin(stype)) imin(stype)=i-2
                if (imin(stype).lt.1) imin(stype)=1
                goto 333
              endif
            enddo
          enddo
          imin(stype)=1
 333      do i=nbx,1,-1
            do j=1,nby
              if (val2d(i,j).ne.0.) then
                if (i+1.gt.imax(stype)) imax(stype)=i+2
                if (imax(stype).gt.nbx) imax(stype)=nbx
                goto 334
              endif
            enddo
          enddo
          imax(stype)=1
 334      do j=1,nby
            do i=1,nbx
              if (val2d(i,j).ne.0.) then
                if (j-1.lt.jmin(stype)) jmin(stype)=j-2
                if (jmin(stype).lt.1) jmin(stype)=1
                goto 335
              endif
            enddo
          enddo
          jmin(stype)=1
 335      do j=nby,1,-1
            do i=1,nbx
              if (val2d(i,j).ne.0.) then
                if (j+1.gt.jmax(stype)) jmax(stype)=j+2
                if (jmax(stype).gt.nby) jmax(stype)=nby
                goto 336
              endif
            enddo
          enddo
          jmax(stype)=1
 336      do i=1,nbx                                                      ! beginning of the loop over all cells along x.
            do j=1,nby                                                    ! beginning of the loop over all cells along y.
              lamplu(i,j,stype)=val2d(i,j)                                ! remplir the array of the lamp type: stype
              totlu(stype)=totlu(stype)+lamplu(i,j,stype)                 ! the total lamp flux should be non-null to proceed to the calculations
            enddo                                                         ! end of the loop over all cells along y.
          enddo                                                           ! end of the loop over all cells along x.
        enddo                                                             ! end of the loop 1 over the nzon types of sources.
c distribute reflectance values and adding fake buildings
        do i=1,nbx                                                        ! beginning of the loop over all cells along x.
          do j=1,nby                                                      ! beginning of the loop over all cells along y.
            if (gndty(i,j).eq.3) then     
               reflec(i,j)=orefl
            elseif (gndty(i,j).eq.2) then   
               reflec(i,j)=srefl
            elseif (gndty(i,j).eq.1) then
               reflec(i,j)=brefl
               altsol(i,j)=altsol(i,j)+obsH(i,j)
            else
               reflec(i,j)=brefl            
            endif                    
          enddo                                                           ! end of the loop over all cells along y.
        enddo
c computation of the tilt of the pixels along x and along y
        do i=1,nbx                                                        ! beginning of the loop over the column (longitude) of the domain.
          do j=1,nby                                                      ! beginning of the loop over the rows (latitu) of the domain.
            if (i.eq.1) then                                              ! specific case close to the border of the domain (vertical side left).
              inclix(i,j)=atan((altsol(i+1,j)-altsol(i,j))/real(dx))      ! computation of the tilt along x of the surface.
            elseif (i.eq.nbx) then                                        ! specific case close to the border of the domain (vertical side right).
              inclix(i,j)=atan((altsol(i-1,j)-altsol(i,j))/(real(dx)))    ! computation of the tilt along x of the surface.
            else
              inclix(i,j)=atan((altsol(i+1,j)-altsol(i-1,j))/(2.          ! computation of the tilt along x of the surface.
     1        *real(dx)))
            endif
            if (j.eq.1) then                                              ! specific case close to the border of the domain (horizontal side down).
              incliy(i,j)=atan((altsol(i,j+1)-altsol(i,j))/(real(dy)))    ! computation of the tilt along y of the surface.
            elseif (j.eq.nby) then                                        ! specific case close to the border of the domain (horizontal side up).
              incliy(i,j)=atan((altsol(i,j-1)-altsol(i,j))/(real(dy)))    ! computation of the tilt along y of the surface.
            else
              incliy(i,j)=atan((altsol(i,j+1)-altsol(i,j-1))/(2.          ! computation of the tilt along y of the surface
     1        *real(dy)))
            endif
          enddo                                                           ! end of the loop over the rows (latitu) of the domain
        enddo                                                             ! end of the loop over the column (longitude) of the domain
        dy=dx
        omefov=0.00000001                                                 ! solid angle of the spectrometer slit on the sky. Here we only need a small value
        z_obs=z_o+altsol(x_obs,y_obs)                                     ! z_obs = the local observer elevation plus the height of observation above ground (z_o)
        rx_obs=real(x_obs)*dx
        ry_obs=real(y_obs)*dy
        if (z_obs.eq.0.) z_obs=0.001
        largx=dx*real(nbx)                                                ! computation of the Width along x of the case.
        largy=dy*real(nby)                                                ! computation of the Width along y of the case.
        write(2,*) 'Width of the domain [NS](m):',largx,'#cases:',nbx
        write(2,*) 'Width of the domain [EO](m):',largy,'#cases:',nby
        write(2,*) 'Size of a cell (m):',dx,' X ',dy
        write(2,*) 'latitu center:',latitu




        layaod=0.
c determination of the vertical atmospheric transmittance
        call transtoa(lambda,bandw,taua,layaod,pressi,tranam,tranaa,      ! tranam and tranaa are the top of atmosphere transmittance (molecules and aerosols)
     +tranal,tabs)
        direct=0.                                                         ! initialize the total direct radiance from sources to observer
        rdirect=0.                                                        ! initialize the total reflected radiance from surface to observer
        irdirect=0.                                                       ! initialize the total direct irradiance from sources to observer
        irrdirect=0.                                                      ! initialize the total reflected irradiance from surface to observer
c =================================
c Calculation of the direct radiances
c
        if (verbose.ge.1) print*,' Calculating obtrusive light...'
        do stype=1,ntype                                                  ! beginning of the loop over the source types.
          if (totlu(stype).ne.0.) then                                    ! check if there are any flux in that source type otherwise skip this lamp
            if (verbose.ge.1) print*,' Turning on lamps',stype
            if (verbose.ge.1) write(2,*) ' Turning on lamps',
     +      stype
            do x_s=imin(stype),imax(stype)                                ! beginning of the loop over the column (longitude the) of the domain.
            do y_s=jmin(stype),jmax(stype)                                ! beginning of the loop over the rows (latitud) of the domain.
              intdir=0.
              itotind=0.
              itodif=0.
              itotrd=0.
              isourc=0.
              rx_s=real(x_s)*dx
              ry_s=real(y_s)*dy
              if (lamplu(x_s,y_s,stype) .ne. 0.) then                     ! if the luminosite of the case is null, the program ignore this case.
                z_s=(altsol(x_s,y_s)+lampal(x_s,y_s))                     ! Definition of the position (metre) vertical of the source.
c
c *********************************************************************************************************
c calculation of the direct radiance of sources falling on a surface perpendicular
c to the viewing angle Units of W/nm/m2/sr
c *********************************************************************************************************
                rx=rx_obs+20000.*ix
                ry=ry_obs+20000.*iy
                rz=z_obs+20000.*iz
                dho=sqrt((rx_obs-rx_s)**2.
     +          +(ry_obs-ry_s)**2.)
                if ((dho.gt.0.).and.(z_s.ne.z_obs)) then
                  call anglezenithal(rx_obs,ry_obs,z_obs                  ! zenithal angle source-observer
     +            ,rx_s,ry_s,z_s,dzen)
                  call angleazimutal(rx_obs,ry_obs,rx_s,                  ! computation of the angle azimutal direct line of sight-source
     +            ry_s,angazi)
                  if (dzen.gt.pi/4.) then                                 ! 45deg. it is unlikely to have a 1km high mountain less than 1
                    call horizon(x_obs,y_obs,z_obs,dx,dy,
     +              altsol,angazi,zhoriz,dh)
                    if (dh.le.dho) then
                      if (dzen-zhoriz.lt.0.00001) then                    ! shadow the path line of sight-source is not below the horizon => we compute
                        hh=1.
                      else
                        hh=0.
                      endif
                    else
                      hh=1.
                    endif
                  else
                    hh=1.
                  endif
               ff=0.   
               if (obsobs.eq.1) then
c sub-grid obstacles
                  if (dho.gt.drefle(x_obs,y_obs)+drefle(x_s,y_s)) then    ! light path to observer larger than the mean free path -> subgrid obstacles
                    angmin=pi/2.-atan2((altsol(x_obs,y_obs)+
     +              obsH(x_obs,y_obs)-z_obs),drefle(x_obs,
     +              y_obs))
                    if (dzen.lt.angmin) then                              ! condition sub-grid obstacles direct.
                      ff=0.
                    else
                      ff=ofill(x_obs,y_obs)
                    endif
                  endif                                                   ! end light path to the observer larger than mean free path
               endif
               call anglezenithal(rx_s,ry_s,z_s                           ! zenithal angle source-observer
     +         ,rx_obs,ry_obs,z_obs,dzen)                  
               ff2=0.
               if (dho.gt.drefle(x_s,y_s)) then                           ! light path from source larger than the mean free path -> subgrid obstacles
                  angmin=pi/2.-atan2((altsol(x_s,y_s)+
     +            obsH(x_s,y_s)-z_s),drefle(x_s,y_s))
                  if (dzen.lt.angmin) then                                ! condition sub-grid obstacles direct.
                     ff2=0.
                  else
                     ff2=ofill(x_s,y_s)
                  endif
               endif                                                      ! end light path to the observer larger than mean free path                  
               call anglezenithal(rx_obs,ry_obs,z_obs                     ! zenithal angle source-observer
     +         ,rx_s,ry_s,z_s,dzen)                  
c projection angle of line to the lamp and the viewing angle
               call angle3points (rx_s,ry_s,z_s,rx_obs,                   ! scattering angle.
     +         ry_obs,z_obs,rx,ry,rz,dang)
               dang=pi-dang
c computation of the solid angle of the line of sight voxel seen from the source
               anglez=nint(180.*(pi-dzen)/pi)+1
               P_dir=pvalno(anglez,stype)
c computation of the flux direct reaching the line of sight voxel
               if ((cos(dang).gt.0.).and.(dang.lt.pi/2.)) then
                  ddir_obs=sqrt((rx_obs-rx_s)**2.+                        ! distance direct sight between source and observer
     +            (ry_obs-ry_s)**2.+(z_obs-z_s)**2.)
c computation of the solid angle 1m^2 at the observer as seen from the source
                  omega=1.*abs(cos(dang))/ddir_obs**2.
                  call transmitm(dzen,z_obs,z_s,ddir_obs,
     +            transm,tranam,tabs)
                  call transmita(dzen,z_obs,z_s,ddir_obs,
     +            haer,transa,tranaa)
                  call transmitl(dzen,z_obs,z_s,ddir_obs,
     +            hlay,transl,tranal)
                  if (dang.lt.dfov) then                                  ! check if the reflecting surface enter the field of view of the observer
                     direct=direct+lamplu(x_s,y_s,stype)*
     +               transa*transm*transl*P_dir*omega*(1.-ff)*(1.-ff2)
     +               *hh/(pi*dfov**2.)                                    ! correction for obstacle filling factor
                  endif
                  irdirect=irdirect+lamplu(x_s,y_s,stype)*
     +            transa*transm*transl*P_dir*omega*(1.-ff)*(1.-ff2)*hh    ! correction for obstacle filling factor
               endif
            endif
c
c **********************************************************************************
c * computation of the direct light toward the observer by the ground reflection   *
c **********************************************************************************
c
            xsrmi=x_s-boxx
            if (xsrmi.lt.1) xsrmi=1
               xsrma=x_s+boxx
               if (xsrma.gt.nbx) xsrma=nbx
               ysrmi=y_s-boxy
               if (ysrmi.lt.1) ysrmi=1
               ysrma=y_s+boxy
               if (ysrma.gt.nby) ysrma=nby
               do x_sr=xsrmi,xsrma                                        ! beginning of the loop over the column (longitude) reflecting.
                  rx_sr=real(x_sr)*dx
                  do y_sr=ysrmi,ysrma                                     ! beginning of the loop over the rows (latitu) reflecting.
                     ry_sr=real(y_sr)*dy
                     irefl=0.
                     z_sr=altsol(x_sr,y_sr)
                     if((x_sr.gt.nbx).or.(x_sr.lt.1).or.
     +                  (y_sr.gt.nby).or.(y_sr.lt.1)) then
                        if (verbose.eq.2) then
                           print*,'Ground cell out of borders'
                        endif
                     else
                        if((x_s.eq.x_sr).and.(y_s.eq.y_sr)
     +                     .and.(z_s.eq.z_sr)) then
                           if (verbose.eq.2) then
                              print*,'Source pos = Ground cell'
                           endif
                        else
                        haut=-(rx_s-rx_sr)*tan(                           ! if haut is negative, the ground cell is lighted from below
     +                  inclix(x_sr,y_sr))-(ry_s-
     +                  ry_sr)*tan(incliy(x_sr,y_sr))+z_s-z_sr
                        if (haut .gt. 0.) then                            ! Condition: the ground cell is lighted from above
c computation of the zenithal angle between the source and the surface reflectance
                           call anglezenithal(rx_s,ry_s,                  ! computation of the zenithal angle between the source and the line of sight voxel.
     +                     z_s,rx_sr,ry_sr,z_sr,                          ! end of the case "observer at the same latitu/longitude than the source".
     +                     angzen)
c computation of the transmittance between the source and the ground surface
                           distd=sqrt((rx_s-rx_sr)**2.
     +                     +(ry_s-ry_sr)**2.+(z_s-z_sr)**2.)
                           call transmitm(angzen,z_s,
     +                     z_sr,distd,transm,tranam,tabs)
                           call transmita(angzen,z_s,
     +                     z_sr,distd,haer,transa,tranaa)
                           call transmitl(angzen,z_s,z_sr,distd,
     +                     hlay,transl,tranal)
c computation of the solid angle of the reflecting cell seen from the source
                           xc=dble(x_sr)*dble(dx)                        ! Position in meters of the observer voxel (longitude).
                           yc=dble(y_sr)*dble(dy)                        ! Position in meters of the observer voxel (latitu).
                           zc=dble(z_sr)                                 ! Position in meters of the observer voxel (altitude).
                           xn=dble(x_s)*dble(dx)                         ! Position in meters of the source (longitude).
                           yn=dble(y_s)*dble(dy)                         ! Position in meters of the source (latitu).
                           zn=dble(z_s)                                  ! Position in meters of the source (altitude).
                           epsilx=inclix(x_sr,y_sr)                      ! tilt along x of the ground reflectance
                           epsily=incliy(x_sr,y_sr)                      ! tilt along x of the ground reflectance
                           if (dx.gt.reflsiz) then                       ! use a sub-grid surface when the reflectance radius is smaller than the cell size
                              if ((x_sr.eq.x_s).and.(y_sr
     +                        .eq.y_s)) then
                                 dxp=reflsiz
                              else
                                 dxp=dx
                              endif
                           else
                              dxp=dx
                           endif
                           if (dy.gt.reflsiz) then
                              if ((x_sr.eq.x_s).and.(y_sr
     +                        .eq.y_s)) then
                                 dyp=reflsiz
                              else
                                 dyp=dy
                              endif
                            else
                               dyp=dy
                            endif
                            r1x=xc-dble(dxp)/2.-xn                        ! computation of the composante along x of the first vector.
                            r1y=yc+dble(dyp)/2.-yn                        ! computation of the composante along y of the first vector.
                            r1z=zc-tan(dble(epsilx))*
     +                      dble(dxp)/2.+tan(dble(epsily))                ! computation of the composante en z of the first vector.
     +                      *dble(dyp)/2.-zn
                            r2x=xc+dble(dxp)/2.-xn                        ! computation of the composante along x of the second vector.
                            r2y=yc+dble(dyp)/2.-yn                        ! computation of the composante along y of the second vector.
                            r2z=zc+tan(dble(epsilx))*
     +                      dble(dxp)/2.+tan(dble(epsily))                ! computation of the composante en z of the second vector.
     +                      *dble(dyp)/2.-zn
                            r3x=xc-dble(dxp)/2.-xn                        ! computation of the composante along x of the third vector.
                            r3y=yc-dble(dyp)/2.-yn                        ! computation of the composante along y of the third vector.
                            r3z=zc-tan(dble(epsilx))*
     +                      dble(dxp)/2.-tan(dble(epsily))                ! computation of the composante en z of the third vector.
     +                      *dble(dyp)/2.-zn
                            r4x=xc+dble(dxp)/2.-xn                        ! computation of the composante along x of the fourth vector.
                            r4y=yc-dble(dyp)/2.-yn                        ! computation of the composante along y of the fourth vector.
                            r4z=zc+tan(dble(epsilx))*
     +                      dble(dxp)/2.-tan(dble(epsily))                ! computation of the composante en z of the fourth vector.
     +                      *dble(dyp)/2.-zn
                            call anglesolide(omega,r1x,                   ! Call of the routine anglesolide to compute the angle solide.
     +                      r1y,r1z,r2x,r2y,r2z,r3x,r3y,
     +                      r3z,r4x,r4y,r4z)
         if (omega.lt.0.) then
           print*,'ERROR: Solid angle of the reflecting surface < 0.'
           stop
         endif
c estimation of the half of the underlying angle of the solid angle       ! this angle servira a obtenir un meilleur isime (moyenne) of
c                                                                         ! P_dir for le cas of grans solid angles the , pvalno varie significativement sur +- ouvang.
                            ouvang=sqrt(omega/pi)                         ! Angle in radian.
                            ouvang=ouvang*180./pi                         ! Angle in degrees.
c computation of the photometric function of the light fixture toward the reflection surface
c=======================================================================
c
                            anglez=nint(180.*angzen/pi)
                            if (anglez.lt.0)
     +                      anglez=-anglez
                            if (anglez.gt.180) anglez=360
     +                      -anglez
                            anglez=anglez+1                               ! Transform the angle in integer degree into the position in the array.
c average +- ouvang
                            naz=0
                            nbang=0.
                            P_indir=0.
                            do na=-nint(ouvang),nint(ouvang)
                              naz=anglez+na
                              if (naz.lt.0) naz=-naz
                              if (naz.gt.181) naz=362-naz                 ! symetric function
                              if (naz.eq.0) naz=1
                              P_indir=P_indir+pvalno(naz,
     +                        stype)*abs(sin(pi*real(naz)
     +                        /180.))/2.
                              nbang=nbang+1.*abs(sin(pi*
     +                        real(naz)/180.))/2.
                            enddo
                            P_indir=P_indir/nbang
c computation of the flux reaching the reflecting surface
                            flrefl=lamplu(x_s,y_s,stype)*
     +                      P_indir*omega*transm*transa*transl
c computation of the reflected intensity leaving the ground surface
                            irefl1=flrefl*reflec(i,j)/pi                        ! The factor 1/pi comes from the normalisation of the fonction
c
c *********************************************************************************************************
c calculation of the direct radiance from reflection falling on a surface perpendicular
c to the viewing angle Units of W/nm/m2/sr
c *********************************************************************************************************
                            dho=sqrt((rx_obs-rx_sr)**2.
     +                      +(ry_obs-ry_sr)**2.)
                            if ((dho.gt.0.).and.(z_s.ne.z_obs)) then
                              call anglezenithal(rx_obs,ry_obs,z_obs      ! zenithal angle source-observer
     +                        ,rx_sr,ry_sr,z_sr,dzen)
                              call angleazimutal(rx_obs,ry_obs,rx_sr,     ! computation of the angle azimutal direct line of sight-source
     +                        ry_sr,angazi)
                              if (dzen.gt.pi/4.) then                     ! 45deg. it is unlikely to have a 1km high mountain less than 1
                                call horizon(x_obs,y_obs,z_obs,dx,dy,
     +                          altsol,angazi,zhoriz,dh)
                                if (dh.le.dho) then
                                  if (dzen-zhoriz.lt.0.00001) then        ! shadow the path line of sight-source is not below the horizon => we compute
                                    hh=1.
                                  else
                                    hh=0.
                                  endif
                                else
                                  hh=1.
                                endif
                              else
                                hh=1.
                              endif
c sub-grid obstacles
               ff=0.
               if (obsobs.eq.1) then
                              if (dho.gt.drefle(x_obs,y_obs)+
     +                        drefle(x_sr,y_sr)) then                     ! light path to observer larger than the mean free path -> subgrid obstacles
                                angmin=pi/2.-atan2((altsol(x_obs,y_obs)
     +                          +obsH(x_obs,y_obs)-z_obs),drefle(x_obs,
     +                          y_obs))
                                if (dzen.lt.angmin) then                  ! condition sub-grid obstacles direct.
                                  ff=0.
                                else
                                  ff=ofill(x_obs,y_obs)
                                endif
                              endif                                       ! end light path to the observer larger than mean free path
               endif
                              
                              
                              
                  call anglezenithal(rx_sr,ry_sr,z_sr                     ! zenithal angle surface-observer
     +            ,rx_obs,ry_obs,z_obs,dzen)                  
                  ff2=0.
                  if (dho.gt.drefle(x_sr,y_sr)) then                      ! light path from reflecting surface larger than the mean free path -> subgrid obstacles
                    angmin=pi/2.-atan2((altsol(x_sr,y_sr)+
     +              obsH(x_sr,y_sr)-z_sr),drefle(x_sr,
     +              y_sr))
                    if (dzen.lt.angmin) then                              ! condition sub-grid obstacles direct.
                      ff2=0.
                    else
                      ff2=ofill(x_sr,y_sr)
                    endif
                  endif                                                   ! end light path to the observer larger than mean free path                                                
                              call anglezenithal(rx_obs,ry_obs,z_obs      ! zenithal angle source-observer
     +                        ,rx_sr,ry_sr,z_sr,dzen)                              
                              
                              
                              
c projection angle of line to the lamp and the viewing angle
                              call angle3points (rx_sr,ry_sr,z_sr,        ! scattering angle.
     +                        rx_obs,ry_obs,z_obs,rx,ry,rz,dang)
                              dang=pi-dang

c computation of the flux direct reaching the line of sight voxel
                              if ((cos(dang).gt.0.).and.(dang.lt.pi/2.))
     +                        then
                                ddir_obs=sqrt((rx_obs-rx_sr)**2.+         ! distance direct sight between source and observer
     +                          (ry_obs-ry_sr)**2.+(z_obs-z_sr)**2.)
c computation of the solid angle of the line of sight voxel seen from the source
                                omega=1.*abs(cos(dang))/ddir_obs**2.
                                call transmitm(dzen,z_obs,z_sr,ddir_obs,
     +                          transm,tranam,tabs)
                                call transmita(dzen,z_obs,z_sr,ddir_obs,
     +                          haer,transa,tranaa)
                                call transmitl(dzen,z_obs,z_sr,ddir_obs,
     +                          hlay,transl,tranal)
                                if (dang.lt.dfov) then                    ! check if the reflecting surface enter the field of view of the observer
                                  rdirect=rdirect+irefl1*omega*transa*
     +                            transm*transl*hh*(1.-ff)*(1.-ff2)
     +                            /(pi*dfov**2.)
                                endif
                                irrdirect=irrdirect+irefl1*omega*transa*
     +                          transm*transl*hh*(1.-ff)*(1.-ff2)
                              endif

                            endif
                          endif
                        endif
                    endif
                  enddo
                enddo

              endif
            enddo
            enddo
          endif
        enddo
c
c End of calculation of the direct radiances
c =================================





        if (verbose.ge.1) print*,'======================================
     +==============='
        print*,'         Direct irradiance from sources (W/m**2/nm)'
        write(*,2001)  irdirect
        print*,'       Direct irradiance from reflexion (W/m**2/nm)'
        write(*,2001)  irrdirect
        print*,'         Direct radiance from sources (W/str/m**2/nm)'
        write(*,2001)  direct
        print*,'         Direct radiance from reflexion (W/str/m**2/nm)'
        write(*,2001)  rdirect
        write(2,*) '     Direct irradiance from sources (W/m**2/nm)'
        write(2,2001)  irdirect
        write(2,*) '     Direct irradiance from reflexion (W/m**2/nm)'
        write(2,2001)  irrdirect
        write(2,*) '     Direct radiance from sources (W/str/m**2/nm)'
        write(2,2001)  direct
        write(2,*) '     Direct radiance from reflexion (W/str/m**2/nm)'
        write(2,2001)  rdirect
      close(2)
 2001 format('                   ',E10.3E2)
      stop
      end
c***********************************************************************************************************************
c*                                                                                                                     *
c*                                         end of the programme                                                        *
c*                                                                                                                     *
c***********************************************************************************************************************
