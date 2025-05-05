#include "ShaderStructs.hlsl"
#ifdef DEBUG
//Print number
float DigitBin( const int x )
{
    return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
}
float PrintValue( float2 vStringCoords, float fValue, float fMaxDigits, float fDecimalPlaces )
{       
    if ((vStringCoords.y < 0.0) || (vStringCoords.y >= 1.0)) return 0.0;
    
    bool bNeg = ( fValue < 0.0 );
    fValue = abs(fValue);
    
    float fLog10Value = log2(abs(fValue)) / log2(10.0);
    float fBiggestIndex = max(floor(fLog10Value), 0.0);
    float fDigitIndex = fMaxDigits - floor(vStringCoords.x);
    float fCharBin = 0.0;
    if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
        if(fDigitIndex > fBiggestIndex) {
            if((bNeg) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
        } else {		
            if(fDigitIndex == -1.0) {
                if(fDecimalPlaces > 0.0) fCharBin = 2.0;
            } else {
                float fReducedRangeValue = fValue;
                if(fDigitIndex < 0.0) { fReducedRangeValue = frac( fValue ); fDigitIndex += 1.0; }
                float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
                fCharBin = DigitBin(int(floor(fmod(fDigitValue, 10.0))));
            }
        }
    }
    return floor(fmod((fCharBin / pow(2.0, floor(frac(vStringCoords.x) * 4.0) + (floor(vStringCoords.y * 5.0) * 4.0))), 2.0));
}

half4 _Debug;
half _IsDebugNumber;
float _DebugNumber;
half _IsDebugVertex;
half _LightDebugMode;
half _SurfaceDataDebugMode;
void Debug(half4 colorIn)
{
    _Debug = colorIn;
}
void Debug(half3 colorIn)
{
    _Debug = half4(colorIn, 1);
}

void Debug(half2 colorIn)
{
    _Debug = half4(colorIn, 0, 1);
}
void Debug(half colorIn)
{
    _Debug = half4(colorIn, colorIn, colorIn, 1);
}
//vertex Debug
void Debug(half4 colorIn, out half4 debugColor)
{
    debugColor = colorIn;
}
void Debug(half3 colorIn, out half4 debugColor)
{
    debugColor = half4(colorIn, 1);
}

void Debug(half2 colorIn, out half4 debugColor)
{
    debugColor = half4(colorIn, 0, 1);
}
void Debug(half colorIn, out half4 debugColor)
{
    debugColor = half4(colorIn, colorIn, colorIn, 1);
}
void DebugNumber(float number, float2 uv, out half4 debugColor);
void DebugNumber(float number, float2 uv)
{
    _IsDebugNumber = 1;
    uv = (uv - float2(0, 0.5)) * 8;
    _DebugNumber = PrintValue(uv, number, 3, 4);
}
half4 DebugOut(half4 color)
{
    if(_IsDebugNumber)
    {
        return half4(_DebugNumber, _DebugNumber, _DebugNumber, 1);
    }
    if(length(_Debug.xyz) > 0.01 || _Debug.a > 0)
    {
        return _Debug;
    }
    return color;
}
half4 DebugSD(SurfaceData sd, half4 color)
{
    if(_SurfaceDataDebugMode)
        color.w = 1;
    switch(_SurfaceDataDebugMode)
    {
    case 0:
        
    case 1:
        color.xyz = sd.albedo;
    case 2:
        color.xyz = sd.metallic;
    case 3:
        color.xyz = sd.smoothness;
    case 4:
        color.xyz = sd.occlusion;
    }
    return color;
}
void DebugTrue()
{
    _Debug = 1;
}



#endif

