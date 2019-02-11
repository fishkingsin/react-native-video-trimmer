package com.creedon.reactlibrary.videotrimmer.interfaces;


public interface VideoTrimListener {
    void onStartTrim();
    void onFinishTrim(String inputFile, long startMs, long endMs);
    void onCancel();
}
