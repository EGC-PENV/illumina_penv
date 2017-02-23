c======================================================================
c  Routine lignevisee (Martin Aube 2005)
c
c  Determine les cellules se trouvant dans la ligne de visee (cellules cibles)
c  entre les cellules (x1,y1,z1) et (x2,y2,z2) 
c  Retourne la matrice des cellules cibles (visee) ainsi que le nombre
c  de cellules cibles (ncell)
c
c-----------------------------------------------------------------------
c   
c    Copyright (C) 2009  Martin Aube
c
c    This program is free software: you can redistribute it and/or modify
c    it under the terms of the GNU General Public License as published by
c    the Free Software Foundation, either version 3 of the License, or
c    (at your option) any later version.
c
c    This program is distributed in the hope that it will be useful,
c    but WITHOUT ANY WARRANTY; without even the implied warranty of
c    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c    GNU General Public License for more details.
c
c    You should have received a copy of the GNU General Public License
c    along with this program.  If not, see <http://www.gnu.org/licenses/>.
c
c    Contact: martin.aube@cegepsherbrooke.qc.ca
c
c

      subroutine lignevisee (x1,y1,z1,dx,dy,angvis,angazi,
     + nbx,nby,vistep,cloudz,visfin,ncfin)

      integer x1,y1,cx,cy,visee(1024,3),alim,vistep,visfin(1024,3)
      integer viseef(1024,3),ncellf,cxm,cym,czm,elimf,cloudz
      integer ncell,nbx,nby,a,cxp,cyp,czp,cz,ncfin,domain
      real z1,xn,yn,zn,dx,dy,distance
      real celthi(50),cell_height(50),pi
      real angvis,angazi,ix,iy,iz,amax,da,angaz1,angvi1
      real dminx,dminy,dminz,r,dr,rmax

      parameter (pi=3.1415926)

      data celthi /0.5,0.6,0.72,0.86,1.04,1.26,1.52,1.84,2.22,            ! Epaisseur des niveaux
     a 2.68,3.24,3.92,4.74,5.72,6.9,8.34,10.08,12.18,14.72,17.78,21.48,
     b 25.94,31.34,37.86,45.74,55.26,66.76,80.64,97.42,117.68,142.16,
     c 171.72,207.44,250.58,302.7,365.66,441.72,533.6,644.58,778.66,
     d 940.62,1136.26,1372.6,1658.1,2002.98,2419.6,2922.88,3530.84,
     e 4265.26,5152.44/
                                                                          ! Matrice de la hauteur du centre de chaque niveau (metre)
      data cell_height /0.25,0.8,1.46,2.25,3.2,4.35,5.74,7.42,9.45,       ! Hauteur du centre de chaque niveau
     a 11.9,14.86,18.44,22.77,28.,34.31,41.93,51.14,62.27,75.72,91.97,
     b 111.6,135.31,163.95,198.55,240.35,290.85,351.86,425.56,514.59,
     c 622.14,752.06,909.,1098.58,1327.59,1604.23,1938.41,2342.1,
     d 2829.76,3418.85,4130.47,4990.11,6028.55,7282.98,8798.33,
     e 10628.87,12840.16,15511.4,18738.26,22636.31,27345.16/
      cz=1
      if (cloudz.ne.50) then
         print*,'Cloud base vertical level:',cloudz,'/50'
         print*,'Cloud base height (m):',cell_height(cloudz)
      endif
      rmax=sqrt((real(nbx)*dx)**2.+(real(nby)*dy)**2.+30000.**2.)
      ncell=0
      xn=nint((real(x1-1)*dx))                                            ! Transfert des coordonnees des cellules en mtre
      yn=nint((real(y1-1)*dy))                                            ! Le zero du systeme de reference est au coin superieur gauche du pixel observateur
      zn=z1                                                               !
      angvi1 = (pi*angvis)/180.
      angaz1 = (pi*angazi)/180.
      ix = ( sin((pi/2.)-angvi1) ) * (cos(angaz1))                        ! determiner les projections du vecteur de visee selon chaque axe
      iy = ( sin((pi/2.)-angvi1) ) * (sin(angaz1))
      iz = (cos((pi/2.)-angvi1))
      cxp=0
      cyp=0
      czp=0
      do k = 1,50                                                         ! trouver le niveau initial
         if ((z1 .lt. cell_height(k)+celthi(k)/2.) .and. 
     +   (z1 .ge. cell_height(k)-celthi(k)/2.)) then
            cz= k
         endif
      enddo
      if (celthi(cz).gt.dx) then
         da=(dx+dy)/2./100.
      else
         da=celthi(cz)/100.
      endif                                                               ! determiner l'increment lineaire pour le calcul de la ligne de visee
      if ((real(nbx)*dx.gt.real(nby)*dy).and.(real(nbx)*dx.gt.
     +cell_height(50)+celthi(50)/2.)) then                                ! determiner la dimension maximale a parcourir
         amax=real(nbx)*dx
      elseif ((real(nby)*dy.gt.real(nbx)*dx).and.(real(nby)*dy.gt.
     +cell_height(50)+celthi(50)/2.)) then
         amax=real(nby)*dy
      else
         amax=cell_height(50)+celthi(50)/2.
      endif
      if (amax.lt.cell_height(50)) amax=cell_height(50)
      if (abs(iz).gt.0.017) then 
           alim=2*nint(amax/da/iz)
c           print*,'oblique or vertical'
      else
           alim=2*nint(amax/da)
c           print*,'horizontal'
      endif
      domain=1
      a=0
      r=0.
      dr=da
      cx=x1
      cy=y1
      cz=25                                                               ! somewhere in the middle vertically - in order to begin inside the domain
      do while ((cx.le.nbx).and.(cx.ge.1).and.(cy.le.nby).and.(cy.ge.1)   ! verifier si nous sommes dans le domaine
     +      .and.(cz.le.50).and.(cz.ge.1).and.(r.lt.rmax))
            r=r+dr
            dr=dr*1.005
            cx = x1 + nint(ix*r/dx)
            cy = y1 + nint(iy*r/dy)
            z = z1 + iz*r
            do k = 1,50
               if ((z .lt.cell_height(k)+celthi(k)/2.).and. 
     +         (z .ge. cell_height(k)-celthi(k)/2.)) then
                  cz= k
               endif
            enddo
               domain=1
               if (z.lt.28000.) then
                  dminx=abs((ix*real(a)*da/dx-real(nint(ix*real(a)*       ! calcul de la distance entre le centre de la cellule et la position du vecteur en unite de largeur de cellule
     +            da/dx))))
                  dminy=abs((iy*real(a)*da/dy-real(nint(iy*real(a)*
     +            da/dy))))
                  dminz=abs((z-cell_height(cz))/celthi(cz))
                  distance=sqrt(dminx**2.+dminy**2.+dminz**2.)
                  if (distance.lt.0.5) then                               ! ne retenir que les positions s'approchant a moins de la demi d'une cellule
                     if ((cx.eq.cxp).and.(cy.eq.cyp).and.(cz.eq.czp))     ! s'assurer de ne pas compter plus d'une fois la meme cellule
     +                then
                     else   
                        ncell=ncell+1
                        visee(ncell,1)=cx
                        visee(ncell,2)=cy
                        visee(ncell,3)=cz  
                        cxp=cx
                        cyp=cy
                        czp=cz 
                     endif
                  endif
               endif
         a=a+1
c      print*,'a=',a,r,cx,cy,cz
      enddo



c      print*,'a=',a



c
c  eviter les angles droits successifs
c
      elimf=0
      ncellf=1
      viseef(ncellf,1)=visee(1,1)
      viseef(ncellf,2)=visee(1,2)
      viseef(ncellf,3)=visee(1,3)
      do i=2,ncell-1
         cx=visee(i,1)
         cy=visee(i,2)
         cz=visee(i,3)
         cxp=visee(i+1,1)
         cyp=visee(i+1,2)
         czp=visee(i+1,3)
         cxm=visee(i-1,1)
         cym=visee(i-1,2)
         czm=visee(i-1,3)
         if ((((cxp.eq.cx).and.(cyp.eq.cy).and.(czp.eq.cz+1).and.
     +   ((cxm.ne.cxp).or.(cym.ne.cyp))).or.((cxm.eq.cx).and.
     +   (cym.eq.cy).and.(czm.eq.cz-1).and.((cxm.ne.cxp).or.
     +   (cym.ne.cyp)))).and.(elimf.ne.1)) then
c    un cas a eliminer
            elimf=1
         else      
            ncellf=ncellf+1
            viseef(ncellf,1)=cx
            viseef(ncellf,2)=cy
            viseef(ncellf,3)=cz  
            elimf=0 
         endif
      enddo
      ncellf=ncellf+1
      viseef(ncellf,1)=visee(ncell,1)
      viseef(ncellf,2)=visee(ncell,2)
      viseef(ncellf,3)=visee(ncell,3)
c
c
c arreter le ligne de visee au nuage and forbid cells outside the domain
c
          ncfin=1
          do ii=1,ncellf
             if (viseef(ii,3).le.cloudz) then
                if ((viseef(ncfin,1).le.nbx).and.(viseef(ncfin,1).ge.1)   ! verifier si nous sommes dans le domaine
     +          .and.(viseef(ncfin,2).le.nby).and.(viseef(ncfin,2).ge.1)
     +          .and.(viseef(ncfin,3).le.50).and.(viseef(ncfin,3).ge.1))
     +          then   
                    visfin(ii,1)=viseef(ncfin,1)
                    visfin(ii,2)=viseef(ncfin,2)
                    visfin(ii,3)=viseef(ncfin,3)
                    ncfin=ncfin+1
                endif
             endif
        
          enddo
          vistep=1
          ncfin=ncfin-1
      return
      end
