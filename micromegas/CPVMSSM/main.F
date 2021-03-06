
C====== Modules =================
C   Keys to switch on
C   various modules of micrOMEGAs
C================================
   
#define MASSES_INFO
C    Display information about SUSY and Higgs masses
C#define CONSTRAINTS
C     Display  deltarho, B_>sgamma, Bs->mumu, gmuon and
C     check LEP mass limits 

C#define HIGGSBOUNDS "../Packages/HiggsBounds-4.2.0"
C#define HIGGSSIGNALS "../Packages/HiggsSignals-1.3.0"

#define OMEGA
C    Calculate relic density and display contribution of
C                            individual channels 
#define INDIRECT_DETECTION
C     Compute spectra of gamma/positron/neutrinos
C     for DM annihilation; calculate <sigma*v> and
C     integrate gamma signal over DM galactic squared
C     density for given line of sight.

C#define LoopGAMMA
C       Calculate discrete  photon spectrum caused by annihilation of 
C       neutralinos into two photons and Z-photon

#define CDM_NUCLEON 
C     Calculate amplitudes and cross-sections for
C     CDM-mucleon collisions 

C#define RESET_FORMFACTORS
C     Modify default nucleus form factors, 
C     DM velocity distribution,
C     A-dependence of Fermi-dencity.
C#define CDM_NUCLEUS
C     Calculate number of events for 1kg*day
C     and recoil energy distibution for various nuclei

#define NEUTRINO  for neutrino telescope

C#define DECAYS
C     Calculates particle widths and branchings

#define CROSS_SECTIONS
C     Calculate cross sections and widths for
C      reactions specified by the user

C#define SHOWPLOTS 
C================ end of Modules  ======


C===== Options ========

C!#define SHOWPLOTS
C     Display  graphical plots on the screen

#define CLEAN to clean intermediate files

C===== End of DEFINE  settings ===== 


      IMPLICIT NONE
C! external functions 
#include "../sources/micromegas.fh"
#include "lib/pmodel.fh"

C! local  Parameters
   
      INTEGER fast/1/
      REAL*8  Beps/1.E-4/,cut/0.01/
C Variables      
      INTEGER err
      REAL*8 Omega,OmegaAppr,Xf,val
      INTEGER  narg 
      character *100 argv
      character*10 cdmName
      integer spin2,charge3,cdim,PDGcdm     
      real*8 Pcm,cosmin, cosmax,Qren, Qfact,pTmin
      integer txtL(2),dim
      integer*8 cc
      integer ntot,l, nin,nout
      character*6 name(4)
      real*8 mass(4)
      real*8 cs,width,Etest
      real*8  Emin,sigmaV,fi,dfi
      character*100 buff,mess
      
C for CDM_NUCLEON
      real*8  pA0(2),pA5(2),nA0(2),nA5(2),Nmass,SCcoeff,
     >ffS0P(3),ffS0N(3),ffbuff(3)
C for INDIRECT
      real*8 SpA(NZ),Spe(NZ),SpP(NZ)
      real*8 FluxA(NZ),FluxE(NZ),FluxP(NZ),FluxN(NZ),FluxNb(NZ),FluxMu(NZ)
      real*8 N_tot
C  for CDM_NUCLEUS
      real*8  dNdE(200),nEvents
C for telescope 
      real*8 rhoDet
      integer forSun
C for DECAYS 
       character*20 pname
C for LoopGAMMA
       real*8 vcs_gg,vcs_zg
 
      write(*,*)
      write(*,*) '========= EWSB scale input For CPVMSSM ========='
      if(iargc().eq.0) then
         write(*,*)'Correct usage: ./main  <file with parameters>'
         write(*,*)'Example: ./main  data1.par' 
         stop
      endif

      call getarg(1,argv)                               
       
      err=readVarCPVMSSM(argv)

      if(err.eq.-1) then
          write(*,*) 'Can not open the file'
          stop
      endif

      if(err.gt.0) then
          write(*,*)'Wrong file contents at line ',err
          stop
      endif

      goto 101
100   STOP 'Wrong input' 
101   continue
C  To print list od variables uncomment   
C      CALL printVar(6)

C    to save results in SLHA format  use 
C     Call writeLesH('slha.out') 


      err=sortOddParticles(cdmName)
      if(err.ne.0) then
        write(*,*) 'Can t calculate ', cdmName
        STOP
      endif 

      PDGcdm=qNumbers(cdmName,spin2, charge3,  cdim)
      write(*,fmt="('Dark matter candidate is ', A5,'with spin=',
     >I1,'/2 mass=',1PE10.2)") cdmName, spin2,Mcdm

      if(charge3.ne.0) then 
         write(*,fmt="('DM has electric charge',I1,'/3')") charge3
         STOP
      endif

      if(cdim.ne.1) then 
         write(*,*) 'DM has color charge'
         STOP
      endif

#ifdef MASSES_INFO  
      write(*,*) '=== MASSES OF HIGGS AND SUSY PARTICLES: ===' 
      CALL printHiggs(6)
      CALL printMasses(6,1)
#endif

#ifdef CONSTRAINTS
      write(*,*)
      write(*,*) '==== Physical Constraints: ====='
      write(*,fmt='("EDM(Thallium) =",1PE10.2)') EDMth()
      write(*,fmt='("EDM(electron) =",1PE10.2)') EDMel()
      write(*,fmt='("EDM(muon)     =",1PE10.2)') EDMmu()
      write(*,fmt='("SUSY contr. muon Mag.Mom. =",1PE10.2)')gmuon()
   
      write(*,fmt='("Br(Bs->mu+,mu-)           =",1PE10.2)')Bsmumu()
      write(*,fmt='("Br(Bd->tau+,tau-)         =",1PE10.2)')Bdll()
      write(*,fmt='("Br(B->Xs,gamma)           =",1PE10.2)') Bsg()
      write(*,fmt='("CP_asymm(B->Xs,gamma)     =",1PE10.2,"[%]")')ABsg()
      write(*,fmt='("Br(Bu->tau,nu)/Br(SM)     =",1PE10.2)')Bulnu()
      write(*,fmt='("SUSY mass diff. Bd-bar{Bd}=",1PE10.2)')deltMd()
      write(*,fmt='("SUSY mass diff. Bs-bar{Bs}=",1PE10.2)') deltMs()  

#endif

#ifdef HIGGSBOUNDS
      if(access(HIGGSBOUNDS//"/HiggsBounds",'x') .ne.0) call system('cd '//HIGGSBOUNDS//'; ./configure; make ')
      call system(HIGGSBOUNDS// '/HiggsBounds  LandH SLHA 3 1 cpsuperh2_slha.out HB.out > hb.stdout')
      err=slhaRead("HB.out",1+4)
      write(*,fmt='("HB result=",1PE10.1,"obsratio=", E10.1)') slhaVal2("HiggsBoundsResults",0.d0,1,2), slhaVal2("HiggsBoundsResults",0.,1,3)
      if(0.eq.slhaSTRFormat("HiggsBoundsResults","1 5 ||%[^|]||",buff)) write(*,*) "Channel: ", buff
#endif

#ifdef HIGGSSIGNALS
#define DataSet " latestresults "
C#define Method  " peak " 
C#define  Method " mass "
#define  Method " both "
C* PDF 1 - box ; 2 = Gaussian; 3 box+Gaussia
#define PDF  " 2 " 
#define dMh " 2 " 
      write(*,*) 'HiggsSignals:'
      if(access(HIGGSSIGNALS// '/HiggsSignals','x').ne.0 ) call system( 'cd ' //HIGGSSIGNALS//'; ./configure; make')
      call system('rm -f HS.in HS.out')
      call system('cp cpsuperh2_slha.out HS.in')
      call system('echo "BLOCK DMASS" >> HS.in')
      call system('echo "  25 '//dMh// '" >> HS.in')
      call system(HIGGSSIGNALS//'/HiggsSignals'//DataSet//Method//PDF//'SLHA 3 1 HS.in > hs.stdout');
      call system('grep -A 10000  HiggsSignalsResults HS.in > HS.out')
      err=slhaRead('HS.out',1+4)
      
#undef dMh
#undef PDF
#undef Method
#undef DataSet

#endif


#ifdef OMEGA
      write(*,*)
      write(*,*) '==== Calculation of relic density ====='
C to exclude processes with virtual W/Z in DM   annihilation      
      call  setVVdecay(0,0)

C to include processes with virtual W/Z  also  in co-annihilation 
C     call setVVdecay(2,2)  


      write(*,*) 'Dark Matter candidate is ', cdmName                                   
      if(cdmName.ne.'~o1') then
          write(*,*) '~o1 is not LSP'
      else
          call o1Contents(6)
      endif                                                                          
      Omega=darkOmega(Xf,fast,Beps)
      write(*,fmt='(a,3x,1PE10.2)') 'Omega=',Omega

      OmegaAppr=printChannels(Xf,cut,Beps,1,6)
C restore default VZdecay and VWdecay
       call  setVVdecay(1,1)
#endif

#ifdef  INDIRECT_DETECTION
      write(*,*) 
      write(*,*) '=============== Indirect detection ==========='

C** Emin - energy cut in GeV
      Emin=1     
      Etest=Mcdm/2
C** fi angle of sight [rad], dfi - half of cone angle    
      fi=0.1
      dfi=0.05
      sigmaV=calcSpectrum(1+4,SpA,SpE,SpP,NULL,NULL,NULL,err)    
C  Returns  sigma*v in cm^3/sec.
C  SpX - calculated spectra of annihilation.
C  Use SpectdNdE(E, SpX) to calculate energy distribution in 1/GeV units.
      write(*,*)
      write(*,fmt="('sigma*v=',1PE8.2,'[cm^3/s]')") sigmaV

      write(*,*) 'Photons'
      call gammaFluxTab(fi,dfi, sigmaV, SpA,  FluxA)
      write(*,fmt="('Phonton flux  for angle of sight ',
     < F4.2,'[rad]')") fi
      write(*,fmt="('and spherical region described by cone with angle '
     >,F4.2,'[rad]' )") 2*dfi
#ifdef SHOWPLOTS      
      write(mess,fmt="('gamma flux[cm^2 s GeV]^{-1} at fi=',F4.2,
     > ' from cone with angle=',F4.2,'[rad]')")fi,dfi*2  
      err= displaySpectrum(mess,Emin,Mcdm,FluxA)
#endif
      write(*,fmt="('Photon flux =',1PE8.2,
     >'[cm^2 s GeV]^{-1} for E=',0PF5.1,'[GeV]')")
     > SpectdNdE(Etest, FluxA), Etest
 
      write(*,*) 'Positrons'
      call  posiFluxTab(Emin, sigmaV, SpE,  FluxE)

#ifdef SHOWPLOTS      
      err=displaySpectrum('positron flux [cm^2 s sr GeV]^{-1}',
     >Emin,Mcdm,FluxE)
#endif
      write(*,fmt="('Positron flux  = ',1PE8.2,
     >'[cm^2 sr s GeV]^{-1} for E=',0PF6.1,'[GeV]')")
     > SpectdNdE(Etest, FluxE),  Etest     

      write(*,*) 'antiProtons'
      call  pbarFluxTab(Emin, sigmaV, SpP,  FluxP)

#ifdef SHOWPLOTS      
      err=displaySpectrum('a-proton flux [cm^2 s sr GeV]^{-1}',
     >Emin,Mcdm,FluxP)
#endif
      write(*,fmt="('Anti proton flux  = ',1PE8.2,
     >'[cm^2 sr s GeV]^{-1} for E=',0PF6.1,'[GeV]')")
     > SpectdNdE(Etest, FluxP),  Etest     

#endif

#ifdef LoopGAMMA
      if(loopGamma(vcs_zg, vcs_gg).eq.0) then 
         write(*,*) 'Gamma ray lines:'
       
         write(*,fmt="('E=',F6.1,'[GeV] vcs(Z,A)=', 1PE8.2,
     >        '[cm^2/s] flux=',E8.2,'[cm^2 s]^{-1}')") 
     >   Mcdm-91.19*91.19/4/Mcdm, vcs_zg, 
     >   gammaFlux(fi,dfi,vcs_zg)

         write(*,fmt="('E=',F6.1,'[GeV] vcs(A,A)=', 1PE8.2,
     >        '[cm^2/s] flux=',E8.2,'[cm^2 s]^{-1}')") 
     >   Mcdm, vcs_gg, 
     >   2*gammaFlux(fi,dfi,vcs_gg)

      endif
#endif   


#ifdef  CDM_NUCLEON
      write(*,*)
      write(*,*) '==== Calculation of CDM-nucleons amplitudes  ====='   


      err=nucleonAmplitudes(CDM1, pA0,pA5,nA0,nA5)
      write(*,*)'CDM-nucleon amplitudes:'
      write(*,fmt="(' proton:  SI=',1PE9.2,' SD=',E9.2)")pA0(1),pA5(1)
      write(*,fmt="(' neutron: SI=',1PE9.2,' SD=',E9.2)")nA0(1),nA5(1) 

C  nucleon mass
      Nmass=0.939d0

      SCcoeff=4/M_PI*3.8937966E8
     >*(Nmass*Mcdm/(Nmass+ Mcdm))**2
      write(*,*) 'CDM-nucleon cross sections[pb]:'

      write(*,fmt="(' proton  SI=',1PE9.2,' SD=',E9.2)")
     >                           SCcoeff*pA0(1)**2,3*SCcoeff*pA5(1)**2
      write(*,fmt="(' neutron SI=',1PE9.2,' SD=',E9.2)")
     >                           SCcoeff*nA0(1)**2,3*SCcoeff*nA5(1)**2
#endif

#ifdef RESET_FORMFACTORS

C   The user has approach to form factors  which specifies quark contents 
C   of  proton and nucleon via global parametes like
C      <Type>FF<Nucleon><q>
C   where <Type> can be "Scalar", "pVector", and "Sigma"; 
C         <Nucleon>     "P" or "N" for proton and neutron
C         <q>            "d", "u","s"
C
C   calcScalarFF( Mu/Md, Ms/Md, sigmaPiN[MeV], sigma0[MeV])  
C   calculates and rewrites Scalar form factors

      write(*,fmt='(" protonFF (default)  d, u, s ", 1PE10.2,E10.2,E10.2)') ScalarFFPd,ScalarFFPu,ScalarFFPs
      write(*,fmt='(" neutronFF(default)  d, u, s ", 1PE10.2,E10.2,E10.2)') ScalarFFNd,ScalarFFNu,ScalarFFNs

      write(*,*) '===========Redefinition of form factors========='  
      call calcScalarFF(0.553d0,18.9d0,70.d0,35.d0)

C   To restore default form factors of  version 2  call 
C      calc  calcScalarQuarkFF(0.553d0,18.9d0,55.d0,243.5d0);

      write(*,fmt='(" protonFF (new)  d, u, s ", 1PE10.2,E10.2,E10.2)') ScalarFFPd,ScalarFFPu,ScalarFFPs
      write(*,fmt='(" neutronFF(new)  d, u, s ", 1PE10.2,E10.2,E10.2)') ScalarFFNd,ScalarFFNu,ScalarFFNs

#endif


#ifdef CDM_NUCLEUS
      write(*,*)
      write(*,*)'=========  Direct Detection ==========='

      write(*,*) 'Ge:'

      nEvents=nucleusRecoil(Maxwell,73,Z_Ge,J_Ge73,SxxGe73,dNdE)
C  See '../sources/micromegas.h' for description of arguments
C  Instead of Maxwell  one can use 'fDvDelta' Delta-function
C  velocity distribution.
      write(*,fmt="('Total number of events=',1PE9.2,' /day/kg')") 
     >nEvents

      write(*,fmt=
     >"(' Number of events in 10 - 50 KeV region=',1PE9.2,' /day/kg')") 
     >cutRecoilResult(dNdE,10.d0,50.d0) 


#ifdef SHOWPLOTS
       err=displayRecoilPlot(dNdE,
     >       'Distribution of recoil energy of 73Ge',0.d0,199.d0)
#endif
       write(*,*)
       write(*,*) '131Xe:'  
       nEvents=nucleusRecoil(Maxwell,131,Z_Xe,J_Xe131,SxxXe131,dNdE)

      write(*,fmt=
     >"('Total number of events=',1PE9.2,' /day/kg')")nEvents
      write(*,fmt="(' Number of events in 10 - 50 KeV region=',
     >   1PE9.2, ' /day/kg')")cutRecoilResult(dNdE,10.d0,50.d0)


#ifdef SHOWPLOTS
      err=displayRecoilPlot(dNdE,
     >    'Distribution of recoil energy of 131Xe',0.d0,199.d0)
#endif
#endif

#ifdef NEUTRINO
      forSun=1 
      Emin=1  
C rhoDet - detector density
      rhoDet=1     
      write(*,*)  
      write(*,fmt='("===============Neutrino Telescope=======  for  ",$)')

      if(forSun.ne.0) then
         write(*,*) "Sun" 
      else 
         write(*,*) "Earth"
      endif 
      Emin=0.1
      err=neutrinoFlux(Maxwell,forSun, FluxN,FluxNb)
#ifdef SHOWPLOTS
      err=displaySpectrum("nu flux from Sun [1/Year/km^2/GeV]",Emin,Mcdm,FluxN)
      err=displaySpectrum("nu-bar from Sun  [1/Year/km^2/GeV]",Emin,Mcdm,FluxNb)
#endif
      write(*,fmt='("E>", 1PE8.2," GeV neutrino flux =", E8.2," [1/Year/km^2]")') Emin,spectrInfo(Emin,FluxN,NULL)
      write(*,fmt='("E>", 1PE8.2," GeV anti-neutrino flux =", E8.2," [1/Year/km^2]")') Emin,spectrInfo(Emin,FluxNb,NULL)

C!  ICE CUBE
      if(forSun.eq.1) then 
         write(*,fmt='("IceCube22 exclusion confidence level = ",1PE8.2,"%")') 100*exLevIC22(FluxN,FluxNb,NULL)
      endif
  
C ======  Upward events
  
      call muonUpward(FluxN,FluxNb,FluxMu)
#ifdef SHOWPLOTS  
      err= displaySpectrum("Upward muons[1/Year/km^2/GeV]",Emin,Mcdm/2,FluxMu)
#endif

      write(*,fmt='("E>", 1PE8.2," GeV Upward muon flux =", E8.2," [1/Year/km^2]")') Emin,spectrInfo(Emin,FluxMu,NULL)
  
C ======  Contained events
      call muonContained(FluxN,FluxNb,rhoDet, FluxMu)
#ifdef SHOWPLOTS  
      err=displaySpectrum("Contained  muons[1/Year/km^3/GeV]",Emin,Mcdm,FluxMu)
#endif
      write(*,fmt='("E>", 1PE8.2," Contained muon flux =", E8.2," [1/Year/km^3]")') Emin,spectrInfo(Emin,FluxMu,NULL)
#endif

#ifdef DECAYS

      write(*,*)
      write(*,*)'======Calculations of widths======='

      write(*,*)
      pname = 'h1'
      width=pWidth(pname,txtL)
      write(*,fmt="(A8, ':  total width ',1PE8.2,'[GeV]')") pname, width
      write(*,*)'and Branchings:'
      call printTxtList(txtL,6)  

      write(*,*)
      pname = '~o2'
      width=pWidth(pname,txtL)
      write(*,fmt="(A8,':  total width ',1PE8.2,'[GeV]')")pname, width
      write(*,*)'and Branchings:'
      call printTxtList(txtL,6)  

#endif


#ifdef CROSS_SECTIONS
      write(*,*)
      write(*,*)'======Calculations of cross sections======='
      write(*,*) ' Process p,p -> ~o1,~o2'
      Pcm=4000 
      Qren=pMass("~o2")
      Qfact=Qren
      pTmin=0
      cs=hCollider(Pcm,1,3,Qren, Qfact, "~o1","~o2",pTmin,1)
      write(*,fmt="(1PE8.2,'[pb]')") cs     
#endif

#ifdef CLEAN
       call system(" rm -f CPsuperH.in cpsuperh2_slha.out CPsuperH.out Key.dat nngg.in nngg.out")
       call system("rm -f debug_channels.txt debug_predratio.txt HB.in HB.out HS.in HS.out hb.stdout hs.stdout")       
#endif
         call killPlots
      END

