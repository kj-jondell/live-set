/*
* TODO: 1. ControlBus controll detuning
* 4. general cleanup
****** a) renaming variables...
* 4.5 break into several sc-files...
* 10. outputs???
* 11. Write LaunchPad-class..... 
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
        var drumMachinePads = #[68,69,70,71];
        var padStates = [0,0,0];
        var activeResonatorPad = 0; //change to active pad..
        var activeDrumPad = 0;
        var processingPads = #[80, 81];
        var onColor = 120, offColor = 122, stopBlink = 11, stopRest = 13;
        var blinkPad = {arg midi, blinkOn, blinkOff;
            launchPad.noteOn(0, midi, blinkOn);
            0.05.wait;
            launchPad.noteOn(0, midi, blinkOff);
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

        //COOL  NAME : MACHINE DRUM
        //TODO: RENAME FOLLOWING VARIABLES....
        var choices = [1,4,9,16,25].normalizeSum;
        var possibleDurations = [
            [1/3, 1/4, 1],
            [1, 1/3, 1/8, 1/4],
            [1/16, 1/5, 1/4, 1/8],
            [1/8]
        ];
        var durations = possibleDurations[0];//[1/9, 3/16, 3/24, 1/7, 1/8];
        //var durations = [1/18,1/1,1/9];
        var rates = Tuning.just.ratios.collect(_.round(0.001))[0..2]; 
        //var rates = rates++(1/rates[1..]);
        var subAmt = 88, offset = 16;

        var resetPads = {
            processingPads.do({
                arg val, index;
                launchPad.noteOn(0, val, offColor);
            });
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
                launchPad.noteOn(0, val, if(activeResonatorPad == index, {onColor}, {offColor}))
            });
            drumMachinePads.do({
                arg val, index;
                launchPad.noteOn(0, val, if(activeDrumPad == index, {onColor}, {offColor}))
            });
        };

        ///////////////////////////////////LOAD BUFFERS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
        Buffer.freeAll(s);
        order.do({
            arg index, count;
            var url = File.getcwd +/+ format("/media/wavetable2048/blodsocker%.wav", index+1);
            buffers.add(Buffer.read(s, path: url, numFrames: 2048));
        });
        harshBuffer = Buffer.read(s, path: File.getcwd +/+ "media/electricity.aif");
        slices = SoundFile.collectIntoBuffers(File.getcwd +/+ "media/normalized/*", s);

        s.sync;

        oscProcessing = NetAddr.new("192.168.2.2", 7777); // raspi ip 192.168.2.2
        (File.getcwd +/+ "defs/synth-defs.sc").load(); //load Synth Defs

        ///////////////////////////////////PBINDS\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 

        Pbindef.new(\sequencer,
           \instrument, \sliceBuffer,
           \rate, Pfunc({rates.choose}),
           \bufnum, Pfunc({
               var total = offset+subAmt;
               slices.mirror[offset..(offset+subAmt)].choose.bufnum;
           }),
           \dur, Pfunc({durations.wchoose(choices[0..durations.size-1].normalizeSum);}),
           \triggered, Pfunc { |e| oscProcessing.sendMsg("/triggered", e[\rate] ) },
           \add, Pfunc { fork{
               0.1.wait;
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
                0, {
                    if(leftDiabetes.isPlaying(),
                    {
                        oscProcessing.sendMsg("/terrainFade", val.linlin(0,127,0,255).asInteger);
                    }); 
                },
                4, {
                    if(harshNoise.isPlaying(),
                    {
                        oscProcessing.sendMsg("/starsTransition", val);
                    }); 
                },
                7, {
                    oscProcessing.sendMsg("/earthTransition", val);
                },
                16, {
                    if(leftDiabetes.isPlaying(),
                    {
                        oscProcessing.sendMsg("/terrainHeight", val);
                        oscProcessing.sendMsg("/flySpeed", val.linlin(0,127,0.0,1.0));

                        leftDiabetes.set(\freq,val.linexp(0,127,70,110)); 
                        leftDiabetes.set(\buf,val.linlin(0,127,5,28)); 
                        leftDiabetes.set(\velocity,val.linexp(0,127,30,120)); 
                        leftDiabetes.set(\detuneFactor, val.linlin(0,127,0.7,0));
                    }
                );

                if(rightDiabetes.isPlaying(),
                {
                    rightDiabetes.set(\detuneFactor, val.linlin(0,127,0.6,0));
                    rightDiabetes.set(\velocity,val.linexp(0,127,25,120)); 
                    rightDiabetes.set(\freq,val.linexp(0,127,80,110)); 
                    rightDiabetes.set(\buf,val.linlin(0,127,0,28)); 
                }
            );
        },
        17, {
            oscProcessing.sendMsg("/moireAngle", val);
        },
        18, {
            if(moireBassSynth.isPlaying(),
            {
                moireBassSynth.set(\detune, val.linlin(0,127,1,5));
                oscProcessing.sendMsg("/starHue", val);
            }
        );
        if(moireSynth.isPlaying(),
        {moireSynth.set(\detune, val.linlin(0,127,1,5));});
        if(harshNoise.isPlaying(),
        {harshNoise.set(\midi_gate_level, val.linlin(0,127,0.25,-0.25));});
    },
    20, {
        if(Pbindef(\sequencer).isPlaying(),{
            subAmt = val.linlin(0,127,0,slices.size).asInteger();
        });
    },
    21, {
        if(Pbindef(\sequencer).isPlaying(),{
            offset = val.linlin(0,127,0,slices.size).asInteger();
        });
    }
);
        });

        MIDIFunc.noteOn({arg val, num;
            processingPads.do({
                arg val, ind;
                if(num == val, {
                    fork {blinkPad.value(val, onColor, offColor);} 
                });
            });
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
                    fork {blinkPad.value(num, stopBlink, stopRest);};
                });
            });

            ///RESONATOR PADS
            resonatorPads.do({
                arg val, ind;
                if(num == val){
                    activeResonatorPad = ind;

                    launchPad.noteOn(0, resonatorPads[ind], onColor);
                    launchPad.noteOn(0, resonatorPads[(ind+1)%resonatorPads.size], offColor);
                }
            });

            drumMachinePads.do({
                arg value, ind; 
                if(num == value and: {ind != activeDrumPad}, {
                    launchPad.noteOn(0, drumMachinePads[activeDrumPad], offColor);
                    activeDrumPad = ind;
                    launchPad.noteOn(0, drumMachinePads[ind], onColor);

                    durations = possibleDurations[ind];
                });
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
fork {blinkPad.value(99, stopBlink, stopRest);};
                },
                processingPads[0], {
                    oscProcessing.sendMsg("/prevStage");
                },
                processingPads[1], {
                    oscProcessing.sendMsg("/nextStage");
                }
            );
        }, chan: 0);

        //If user changes from Session/User1/User2/Mixer mode on LaunchPad...
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
s.meter

OSCFunc.trace(false)
