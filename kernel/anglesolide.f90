!----------------------------------------------------------------------- 
 
!======================================================================= 
! Routine anglesolide 
 
! Calcule l'angle solide couvert par la cellule (x_c,y_c,z_c) vue de la 
! cellule (x_n,y_n,z_n) 
 
! Retourne l'angle solide omega 
 
! pour utilisation avec Illumina 
!----------------------------------------------------------------------- 
 
!    Copyright (C) 2009  Martin Aube 
 
!    This program is free software: you can redistribute it and/or modify 
!    it under the terms of the GNU General Public License as published by 
!    the Free Software Foundation, either version 3 of the License, or 
!    (at your option) any later version. 
 
!    This program is distributed in the hope that it will be useful, 
!    but WITHOUT ANY WARRANTY; without even the implied warranty of 
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
!    GNU General Public License for more details. 
 
!    You should have received a copy of the GNU General Public License 
!    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
 
!    Contact: martin.aube@cegepsherbrooke.qc.ca 
 
! Debut de la routine sterad. 
subroutine anglesolide(omega,r1x,r1y,r1z, &
              r2x,r2y,r2z,r3x,r3y,r3z,r4x,r4y,r4z) 
! Variables utilisees pour le calcul d'omega. 
    real(8) :: r1x,r1y, &
              r1z,r2x,r2y,r2z,r3x,r3y,r3z,r4x,r4y,r4z,r1,r2,r3,r4,tet12, &
              tet23,tet13,tet34,tet24,a,b,c,s,a123,a234,arg 
    real :: omega 
    r1 = dsqrt(r1x**2.+r1y**2.+r1z**2.)                                   ! Calcul de la norme du vecteur #1. 
    r2 = dsqrt(r2x**2.+r2y**2.+r2z**2.)                                   ! Calcul de la norme du vecteur #2. 
    r3 = dsqrt(r3x**2.+r3y**2.+r3z**2.)                                   ! Calcul de la norme du vecteur #3. 
    r4 = dsqrt(r4x**2.+r4y**2.+r4z**2.)                                   ! Calcul de la norme du vecteur #4. 
    if (r1 == 0.) then 
      print*,'ERREUR r1 = 0' 
      stop 
    end if 
    if (r2 == 0.) then 
      print*,'ERREUR r2 = 0' 
      stop 
    end if 
    if (r3 == 0.) then 
      print*,'ERREUR r3 = 0' 
      stop 
    end if 
    if (r4 == 0.) then 
      print*,'ERREUR r1 = 0' 
      stop 
    end if 
 
    arg = (r1x*r2x+r1y*r2y+r1z*r2z)/(r1*r2) 
    if (arg > 1.0) arg = 1.0 
    if (arg < -1.0) arg = -1.0 
    tet12 = dacos(arg)                      ! Calcul de l'angle entre le vecteur #1 et le vecteur #2. 
 
    arg = (r2x*r3x+r2y*r3y+r2z*r3z)/(r2*r3) 
    if (arg > 1.0) arg = 1.0 
    if (arg < -1.0) arg = -1.0 
    tet23 = dacos(arg)                      ! Calcul de l'angle entre le vecteur #2 et le vecteur #3. 
 
    arg = (r3x*r1x+r3y*r1y+r3z*r1z)/(r3*r1) 
    if (arg > 1.0) arg = 1.0 
    if (arg < -1.0) arg = -1.0 
    tet13 = dacos(arg)                      ! Calcul de l'angle entre le vecteur #1 et le vecteur #3. 
 
    arg = (r3x*r4x+r3y*r4y+r3z*r4z)/(r3*r4) 
    if (arg > 1.0) arg = 1.0 
    if (arg < -1.0) arg = -1.0 
    tet34 = dacos(arg)                      ! Calcul de l'angle entre le vecteur #3 et le vecteur #4. 
 
    arg = (r2x*r4x+r2y*r4y+r2z*r4z)/(r2*r4) 
    if (arg > 1.0) arg = 1.0 
    if (arg < -1.0) arg = -1.0 
    tet24 = dacos(arg)                      ! Calcul de l'angle entre le vecteur #2 et le vecteur #4. 
 
    a = tet23 
    b = tet13 
    c = tet12 
    s = (a+b+c)/2. 
    if ((dtan(s/2.)*dtan((s-a)/2.)*dtan((s-b)/2.)* &
              dtan((s-c)/2.)) < 0.) then 
    a123 = 0. 
    else 
! Calcul de l'aire du triangle spherique borne par les vecteurs 1,2 et 3. 
      a123 = 4.*datan(dsqrt(dtan(s/2.)*dtan((s-a)/2.)*dtan((s-b)/2.)* &
                dtan((s-c)/2.))) 
    end if 
!         alp=2.*atan(sqrt(sin(s-b)*sin(s-c)/(sin(s)*sin(s-a))))          ! Autre methode pour calculer l'angle solide non utilisee. 
!         bet=asin(sin(b)*sin(alp)/sin(a))                                ! Autre methode pour calculer l'angle solide non utilisee. 
!         gam=asin(sin(c)*sin(alp)/sin(a))                                ! Autre methode pour calculer l'angle solide non utilisee. 
!         a123=alp+bet+gam-pi                                             ! Autre methode pour calculer l'angle solide non utilisee. 
 
    a = tet23 
    b = tet34 
    c = tet24 
    s = (a+b+c)/2. 
 
 
    if ((dtan(s/2.)*dtan((s-a)/2.)*dtan((s-b)/2.)* &
              dtan((s-c)/2.)) < 0.) then 
    a234 = 0. 
    else 
! Calcul de l'aire du triangle spherique borne par les vecteurs 2,3 et 4. 
      a234 = 4.*datan(dsqrt(dtan(s/2.)*dtan((s-a)/2.)*dtan((s-b)/2.)* &
                dtan((s-c)/2.))) 
 
    end if 
!         alp=2.*atan(sqrt(sin(s-b)*sin(s-c)/(sin(s)*sin(s-a))))          ! Autre methode pour calculer l'angle solide non utilisee. 
!         bet=asin(sin(b)*sin(alp)/sin(a))                                ! Autre methode pour calculer l'angle solide non utilisee. 
!         gam=asin(sin(c)*sin(alp)/sin(a))                                ! Autre methode pour calculer l'angle solide non utilisee. 
!         a234=alp+bet+gam-pi                                             ! Autre methode pour calculer l'angle solide non utilisee. 
    omega = real(a123+a234)                                               ! L'angle solide est la somme des aires des deux triangles spheriques. 
 
    return                                                              ! Retour au programme. 
    end                                                                 ! Fin de la routine sterad. 
