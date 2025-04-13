#ifdef DEBUG
half4 _Debug;
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
half4 DebugOut(half4 color)
{
    if(length(_Debug.xyz) > 0.01 || _Debug.a > 0)
    {
        return _Debug;
    }
    return color;
}
#endif
