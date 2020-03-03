/*
* TODO: 1. ControlBus controll detuning
* 4. general cleanup
****** a) renaming variables...
* 4.5 break into several sc-files...
* 10. outputs???
* 
* - MIDI drum machine
* - MIDI harshNoise
* ® Karl Johannes Jondell
*/

(
    s.options.device = "Soundflower (64ch)";
    s.options.memSize = 8192*4;
    MIDIClient.init;
    MIDIIn.connectAll;

    s.waitForBoot({
        ///////////////////////////////////VARIABLES\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
        // Launchpad led-variables
        var launchPad = MIDIOut.newByName("Launchpad Mini", "Launchpad Mini", false);
        var onPads = #[64,66,96], offPads = #[65,67,97];
        var resonatorPads = #[36,37];
        var padStates = [0,0,0];
        var resonatorPadStates = [0,0];
        var onColor = 120, offColor = 122, stopBlink = 11, stopRest = 13;
        var blinkPad = {arg midi;
            launchPad.noteOn(0, midi, stopBlink);
            0.05.wait;
            launchPad.noteOn(0, midi, stopRest);
        };

        //Bus declarations
        var noiseLeftBus = 23, noiseRightBus = 24, moireBassRightBus = 8, moireBassLeftBus = 9, moireLeftBus = 6, moireRightBus = 7, diabetesLeftBus = 0, diabetesRightBus = 1, harshBus = 2, drumMachineBus = 4;

        //General variables
        var oscProcessing;

        //Diabetes variable declarations
        var leftDiabetes, rightDiabetes; 
        //order wavetable-buffers from low to hi spectral centroid frequency
        var order = #[17, 2, 19, 4, 9, 22, 13, 20, 23, 12, 24, 8, 18, 5, 0, 16, 7, 3, 10, 6, 1, 27, 14, 21, 26, 28, 11, 29, 25, 15]; //spectral centroid ordered from low to hi
        var buffers = Array.new(order.size);

        //Moiré variable declarations
        var leftNoise, rightNoise, moireSynth, moireBassSynth;
        var sourceGroup, fxGroup;
        var customScale = {
            arg note, root = 29, tuning = 45;
            var ratios = [1, 19/18, 10/9, 6/5, 5/4, 47/36, 25/18, 53/36, 55/36, 5/3, 67/36, 23/12]; //TODO: FIX RATIOS!
            ratios[(note-root)%ratios.size]*tuning*((note-root)/ratios.size+1).floor;
        };

        //Harsh noise variable declarations
        var harshNoise, harshBuffer;

        //Noise drum machine variable declarations
        var slices; //Normalized buffers (!)

        //TODO: RENAME FOLLOWING VARIABLES....
        var choices = [1,4,9,16,25].normalizeSum;
        var durations = [1/9, 3/16, 3/24, 1/7, 1/8];
        //var durations = [1/18,1/1,1/9];
        var rates = Tuning.just.ratios.collect(_.round(0.001))[0..2]; 
        //var rates = rates++(1/rates[1..]);
        var subAmt = 88, offset = 16;

        var resetPads = {
            onPads.do({
                arg val, index; 
                launchPad.noteOn(0, val, if(padStates[index] == 1, {onColor}, {offColor}));
            });
            (offPads++[99]).do({
                arg val; 
                launchPad.noteOn(0, val, stopRest);
            });
            resonatorPads.do({
                arg val, index;
                launchPad.noteOn(0, val, if(resonatorPadStates[index] == 1, {onColor}, {offColor}))
            });
        };

        //Load buffers
        Buffer.freeAll(s);
        order.do({
            arg index, count;
            var url = format("/Users/kj/Documents/school/supercollider/projects/diabetes/samples/wavetable2048/blodsocker%.wav", index+1);
            buffers.add(Buffer.read(s, path: url, numFrames: 2048));
        });
        harshBuffer = Buffer.read(s, path: File.getcwd +/+ "media/electricity.aif");
        slices = SoundFile.collectIntoBuffers(File.getcwd +/+ "media/normalized/*", s);

        s.sync;

        oscProcessing = NetAddr.new("localhost", 7771); // raspi ip 192.168.2.2

        ///////////////////////////////////SYNTH DEFS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 

        //WAVETABLE (interpolating)
        //TODO: controlbus for detuning AND buffernr
        //Vosc3 for detuning (?)
        //map velocity to amplitude and filter differently
        //Line.kr? have some argument controlling end buf num?
        //how should buf num be controlled? with a ControlBus?
        //Rel?? attack??
        SynthDef.new(
            \diabetes,
            {
                arg freq = 440, velocity = 67, detuneFactor = 1.0, buf = 1, pan = 0;
                var sig = VOsc3.ar(buf, freq1:freq, freq2:freq*(1.0-(detuneFactor*0.5)), freq3:freq*(1.0+(detuneFactor*0.5)), mul: Lag2.kr(velocity.linlin(0,127,-24,-3).dbamp));
                var filter = LPF.ar(sig, freq*Lag2.kr(velocity.linlin(0,127,0.75,12)));
                Out.ar(pan,filter);
        }).add;

        //Remove in future
        SynthDef.new(\noise, {
            arg out;
            var sig;
            sig = WhiteNoise.ar(mul: -3.dbamp);
            Out.ar(out, sig);
        }).add;

        //Output-bus should be selectable
        SynthDef.new(\Interference, {
            arg freq_bus = 1, harmonics = 1.0, in_left = 23, in_right = 24, freq = 440, out_left = 0, out_right = 1;
            //var freq = In.kr(freq_bus);
            var left = In.ar(in_left), right = In.ar(in_right); //instead of left + right, make arbitrary number of sources that can be detuned
            var taps = 12;
            taps.do{|i| left = (DelayC.ar(left, 1, delaytime: (1+i)/(freq), mul: harmonics**(1/(1+i)), add: left));} ;
            taps.do{|i| right = (DelayC.ar(right, 1, delaytime: (1+i)/(freq+\detune.kr(1)), mul: harmonics**(1/(1+i)), add: right));} ;
            Out.ar([out_left,out_right], [0.5*Limiter.ar(0.5*((left)/(1+(harmonics**1.35)*2.45))),0.5*Limiter.ar(0.5*((right)/(1+(harmonics**1.35)*2.45)))]); 
        }).add;

        SynthDef.new(\sliceBuffer, {
            arg bufnum = 0, rate = 1, pan = 0, out_bus = 0;
            var signal = PlayBuf.ar(2, bufnum, rate*BufRateScale.kr(bufnum), doneAction:Done.freeSelf);
            var panner = Pan2.ar(in: signal,  pos: pan, level: 0.5);
            Out.ar(out_bus, panner);
        }).add;

        SynthDef.new(\gatedBuffer, {
            arg bufnum, rate = 1, pan = 0, gate_level = 0.2, midi_gate_level = 0.0, out_bus = 2;
            var signal = PlayBuf.ar(2, bufnum, rate*BufRateScale.kr(bufnum), loop: 1);
            var panner = Pan2.ar(in: signal,  pos: pan, level: -3.dbamp);
            var maximum = Peak.kr(signal, LFPulse.kr(5));
            var gate = EnvGen.ar(Env.asr(attackTime: 0.0035,releaseTime:0.08), gate: maximum-gate_level-midi_gate_level);
            Out.ar(out_bus, panner*gate);
        }).add;

        ///////////////////////////////////PBINDS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 

        Pbindef.new(\sequencer,
           \instrument, \sliceBuffer,
           \rate, Pfunc({rates.choose}),
           \bufnum, Pfunc({slices[offset..(subAmt+offset)%slices.size].choose.bufnum;}),
           \dur, Pfunc({durations.wchoose(choices[0..durations.size-1]);}),
           \bla, Pfunc { |e| oscProcessing.sendMsg("/dur", e[\rate] ) },
           \add, Pfunc { fork{
               if(harshNoise.isPlaying(),{
                       harshNoise.set(\gate_level,-0.001); // TODO: maybe design some other way (and change parameter names...)
                       0.5.wait;
               });
               if(harshNoise.isPlaying(),{
                       harshNoise.set(\gate_level,0.25);
               });
            }},
            \out_bus, drumMachineBus,
           \pan, Pwhite(-0.5,0.5,inf)
        );

        s.sync; //wait for Synthdef and buffers...

        ///////////////////////////////////SYNTH GENS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 

        sourceGroup = Group.new;
        fxGroup = Group.after;

        //NOISE FOR MOIRE
        leftNoise = Synth.new(\noise, [\out, noiseLeftBus], sourceGroup);
        rightNoise = Synth.new(\noise, [\out, noiseRightBus], sourceGroup);

        ///////////////////////////////////MIDI DEFINITIONS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 

        //check if left/right diabetes synths are initilized
        MIDIdef.freeAll;
        MIDIFunc.cc({arg val, num;
            switch(num,
                16, {
                    oscProcessing.sendMsg("/terrainHeight", val);
                    oscProcessing.sendMsg("/flySpeed", val.linlin(0,127,0,1));

                    if(leftDiabetes.isPlaying(),
                    {
                        leftDiabetes.set(\freq,val.linexp(0,127,70,110)); 
                        leftDiabetes.set(\buf,val.linlin(0,127,5,28)); 
                        leftDiabetes.set(\velocity,val.linexp(0,127,10,120)); 
                        leftDiabetes.set(\detuneFactor, val.linlin(0,127,1.0,0));
                    }
                    );

                    if(rightDiabetes.isPlaying(),
                    {
                        rightDiabetes.set(\detuneFactor, val.linlin(0,127,0.9,0));
                        rightDiabetes.set(\velocity,val.linexp(0,127,10,120)); 
                        rightDiabetes.set(\freq,val.linexp(0,127,80,110)); 
                        rightDiabetes.set(\buf,val.linlin(0,127,0,28)); 
                    }
                    );
                },
                18, {
                    if(moireBassSynth.isPlaying(),
                        {moireBassSynth.set(\detune, val.linlin(0,127,1,5);)}
                    );
                    if(moireSynth.isPlaying(),
                        {moireSynth.set(\detune, val.linlin(0,127,1,5);)}
                    );
                }
            );
        });

        MIDIFunc.noteOn({arg val, num;
            /// LIGHT UP LAUNCHPAD
            onPads.do({
                arg val, ind;
                if(num == val, {
                    padStates[ind] = 1;
                    launchPad.noteOn(0, num, onColor);
                });
            });

            /// LIGHT DOWN LAUNCHPAD            
            offPads.do({
                arg val, ind;
                if(num == val, {
                    padStates[ind] = 0;
                    launchPad.noteOn(0, num-1, offColor);
                    fork {blinkPad.value(num);};
                });
            });

            ///RESONATOR PADS
            resonatorPads.do({
                arg val, ind;
                if(num == val){
                    resonatorPadStates[ind] = 1;    
                    resonatorPadStates[(ind+1)%resonatorPadStates.size] = 0;

                    launchPad.noteOn(0, resonatorPads[ind], onColor);
                    launchPad.noteOn(0, resonatorPads[(ind+1)%resonatorPads.size], offColor);
                }
            });

            switch(num,
                onPads[0], { //64
                    //DIABETES SYNTH
                    if(leftDiabetes.isPlaying() == false,
                       {leftDiabetes = Synth.new(\diabetes, [\velocity, 10, \pan, diabetesLeftBus, \freq, 70,\buf, 5, \detuneFactor, 1.0]).register(true);}
                    );
                    if(rightDiabetes.isPlaying() == false,
                        {rightDiabetes = Synth.new(\diabetes, [\velocity, 10, \freq, 80, \buf, 0, \pan, diabetesRightBus, \detuneFactor, 0.9]).register(true);}
                    );
                },
                offPads[0], {//65
                    if(leftDiabetes.isPlaying(),
                        {leftDiabetes.free;}
                    );
                    if(rightDiabetes.isPlaying(),
                        {rightDiabetes.free;}
                    );
                   //TRIGGER OSC SHIFT OF SCENE
                },
                onPads[1], {
                    if(harshNoise.isPlaying() == false,
                        {harshNoise = Synth(\gatedBuffer, [ \bufnum, harshBuffer, \out_buffer, harshBus]).register(true);}
                    );
                },
                offPads[1], {
                    if(harshNoise.isPlaying(),
                        {harshNoise.free;}
                    );
                },
                onPads[2], {
                    if(Pbindef(\sequencer).isPlaying() == false,
                        {Pbindef(\sequencer).play(quant:0);}
                    );
                },
                offPads[2], {
                    if(Pbindef(\sequencer).isPlaying(),
                        {Pbindef(\sequencer).pause;}
                    );
                }, 
                99, {
                    if(moireBassSynth.isPlaying(),
                        {moireBassSynth.free;}
                    );
                    if(moireSynth.isPlaying(),
                        {moireSynth.free;}
                    );
                    fork {blinkPad.value(99);};
                }
            );
        }, chan: 0);

        MIDIFunc.cc({
            arg ...args;
            resetPads.value();
        }, ccNum: 109);

        MIDIFunc.noteOn({
            arg vel, note;
            if(moireBassSynth.isPlaying() == false, {
                moireBassSynth = Synth.new(\Interference, [\harmonics, 0.1, \detune, 1, \in_left, noiseLeftBus, \in_right, noiseRightBus, \freq, customScale.value(note), \out_left, moireBassRightBus, \out_right, moireBassLeftBus], fxGroup).register(true);
            },  {
                moireBassSynth.set(\freq, customScale.value(note));
            });
        }, chan: 5);

        MIDIFunc.noteOn({
            arg vel, note;
            if(moireSynth.isPlaying() == false, {
                moireSynth = Synth.new(\Interference, [\harmonics, 0.1, \detune, 1, \in_left, noiseLeftBus, \in_right, noiseRightBus, \freq, customScale.value(note), \out_left, moireLeftBus, \out_right, moireRightBus], fxGroup).register(true);
            },  {
                moireSynth.set(\freq, customScale.value(note));
            });
        }, chan: 4);

    });

)
/// SERVER FUNCTIONS
s.queryAllNodes();

s.boot;
s.reboot;

s.record;
s.stopRecording;
s.scope;

OSCFunc.trace(false)
