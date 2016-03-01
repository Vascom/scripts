// This function compute coefficients for CIC-filter by given conditions

//############################################################################
//Using
//cic.bin p1 p2 p3 p4 p5 p6
//p1 - Sampling frequency, MHz
//p2 - Pass frequency, MHz. Half of required filter bandpass
//p3 - Required stop level (min), dB. Negative value, like -90
//p4 - Required stop level (max), dB. Negative value, like -80
//p5 - Name of output file. Recommended p1_p2_xx.txt format
//p6 - If present and nonzero then silent mode without console output
//#############################################################################

#include <iostream>
#include <fstream>
#include <math.h>
#include <algorithm>

int main(int argc, char *argv[])
{
    //Sampling frequency, MHz
    const double Fs = atof(argv[1]);
    //Pass frequency, MHz
    const double F_pass = atof(argv[2]);
    //Stop frequency, MHz Usually F_pass+3 MHz
    double F_stop = F_pass + 3;
    //Increment used if initial frequency stop level can't matched
    const double F_stop_incr = 0.5;
    //Required stop level (initial), dB
    const double q_stop_min = atof(argv[3]);
    //Required stop level (max), dB
    const double q_stop_max = atof(argv[4]);
    //Increment used if initial stop level can't matched
    const double q_stop_incr = 1;
    //Min pass level, dB
    const double q_pass = -40;
    //Freq precision. Recommended 5000-10000. 
    //More value - more time and better accuracy
    const short samples = 10000;
    //Length of CIC-filter (min 5)
    const short cic_length = 6;

    std::ofstream out_to_file;
    out_to_file.open(argv[5]);

    double q_stop = q_stop_min;
    bool solution_not_found = true;
    short max_cic = short(floor(Fs/F_stop));
    short s_start = cic_length -1;
    short s = 0;

    bool non_silent_mode = true;
    if(argc==7 && atof(argv[6])!=0) non_silent_mode = false;
    if(non_silent_mode)
        std::cout<<"Maximum CIC delay: "<<max_cic<<std::endl;
    while(solution_not_found && (F_stop-F_pass<6))
    {
        if(q_stop>q_stop_max)
        {
            q_stop = q_stop_min;
            F_stop += F_stop_incr;
        }

        double max_min_m = 513;
        double a_tar0 = -100;
        double a_max0 = 0;
        double a_max = 0;
        double a_tar = 0;
        double max_m = 0;

        double ach0 = 1;
        double ach1 = 1;
        bool dub = true;
        double *g = NULL, *sin_pi=NULL, *ach_log=NULL;
        int *m=NULL;
        short *memory=NULL;
        g = new double[samples];
        sin_pi = new double[samples];
        ach_log = new double[samples];
        m = new int[cic_length];
        memory = new short[int(pow(max_cic,cic_length))];

        if(non_silent_mode)
            std::cout<<F_pass<<" MHz; "<<F_stop<<" MHz; "
            <<q_stop<<" dB."<<std::endl;
        out_to_file<<F_pass<<" MHz; "<<F_stop<<" MHz; "
        <<q_stop<<" dB."<<std::endl;

        for(short i=0; i<samples;i++)
        {
            g[i] = M_PI*(i+1)/(double((samples<<1)));
            sin_pi[i] = pow(sin(g[i]),cic_length);
        }
        short num_Fstop = short(floor(F_stop/Fs*(samples<<1)))-1;

        for(int k =0; k<pow(max_cic,cic_length); k++)
        {
            s = s_start;
            memory[k]=1;
            for(short i=0; i<cic_length; i++)
            {
                if(k%int(pow(max_cic,i))==0) m[s]++;
                if(m[s]>max_cic) m[s] = 1;
                memory[k] *= m[s];
                s--;
            }

            dub = true;
            for(int kk =k-1; kk>=0; kk--)
            {
                if(memory[k]==memory[kk])
                {
                    dub = false;
                    break;
                }
            }
            if(dub)
            {
                ach0 = 1;
                for(short i=0; i<cic_length; i++) ach0 *= sin(m[i]*g[0]);
                ach0 /=sin_pi[0];
                for(short i=0; i<samples;i++)
                {
                    ach1 = 1;
                    for(short j=0; j<cic_length; j++) ach1 *= sin(m[j]*g[i]);
                    ach1 /=sin_pi[i];
                    ach_log[i] = 20*log10(fabs(ach1/ach0));
                }
                a_max = *std::max_element(&ach_log[num_Fstop], 
                                          &ach_log[samples]);
                a_tar = ach_log[int(floor(F_pass/Fs*(samples<<1)))-1];
                max_m = *std::max_element(&m[0], &m[cic_length]);
                if (a_max<q_stop &&  a_tar>q_pass &&
                   (a_tar>a_tar0 || max_m<max_min_m || a_max<a_max0))
                {
                    if(non_silent_mode)
                        std::cout<<a_max<<" dB; "<<a_tar<<" dB."<<std::endl;
                    out_to_file<<a_max<<" dB; "<<a_tar<<" dB."<<std::endl;
                    for(short i=0;i<cic_length;i++)
                    {
                        if(non_silent_mode)
                            std::cout<<m[i]<<" ";
                        out_to_file<<m[i]<<" ";
                    }
                    if(non_silent_mode)
                        std::cout<<std::endl;
                    out_to_file<<std::endl;
                    solution_not_found = false;
                    a_tar0 = a_tar;
                    if(a_max<a_max0) a_max0 = a_max;
                    max_min_m = max_m;
                }
            }
        }
        q_stop += q_stop_incr;
        delete g;
        delete sin_pi;
        delete ach_log;
        delete m;
        delete memory;
    }
    out_to_file.close();
}
