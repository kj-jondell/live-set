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
        var sig = VOsc3.ar(buf, freq1:freq, freq2:freq*(1.0-(detuneFactor*0.5)), freq3:freq*(1.0+(detuneFactor*0.5)), mul: Lag2.kr(velocity.linlin(0,127,-12,-6).dbamp));
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
