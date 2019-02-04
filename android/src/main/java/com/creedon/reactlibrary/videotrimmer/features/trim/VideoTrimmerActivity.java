package com.creedon.reactlibrary.videotrimmer.features.trim;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.databinding.DataBindingUtil;
import android.net.Uri;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;

import com.creedon.reactlibrary.videotrimmer.R;
import com.creedon.reactlibrary.videotrimmer.databinding.ActivityTrimmerLayoutBinding;
import com.creedon.reactlibrary.videotrimmer.interfaces.VideoTrimListener;
import com.creedon.reactlibrary.videotrimmer.utils.RealPathUtils;

public class VideoTrimmerActivity extends AppCompatActivity implements VideoTrimListener {

	private static final String TAG = "jason";
	public static final String VIDEO_PATH_KEY = "VIDEO_PATH_KEY";
	private static final String COMPRESSED_VIDEO_FILE_NAME = "compress.mp4";
	public static final int VIDEO_TRIM_REQUEST_CODE = 0x001;
	public static final String START_MS_KEY = "START_MS_KEY";
	public static final String END_MS_KEY = "END_MS_KEY";
	private ActivityTrimmerLayoutBinding mBinding;
	private ProgressDialog mProgressDialog;
	private String videoPath;

	public static void call(Activity from, String videoPath, long startMs, long endMs) {
		if (!TextUtils.isEmpty(videoPath)) {
			Bundle bundle = new Bundle();
			bundle.putString(VIDEO_PATH_KEY, videoPath);
			bundle.putLong(START_MS_KEY, startMs);
			bundle.putLong(END_MS_KEY, endMs);
			Intent intent = new Intent(from, VideoTrimmerActivity.class);
			intent.putExtras(bundle);
			from.startActivityForResult(intent, VIDEO_TRIM_REQUEST_CODE);
		}
	}

	@Override
	protected void onCreate(Bundle bundle) {
		super.onCreate(bundle);
		mBinding = DataBindingUtil.setContentView(this, R.layout.activity_trimmer_layout);
		Bundle bd = getIntent().getExtras();
		String path = "";
		long startMS = -1;
		long endMs = -1;
		if (bd != null) {
			path = bd.getString(VIDEO_PATH_KEY);
			startMS = bd.getLong(START_MS_KEY, -1);
			endMs = bd.getLong(END_MS_KEY, -1);
		} else {
			setResult(RESULT_CANCELED);
			finish();
		}
		if (mBinding.trimmerView != null) {
			mBinding.trimmerView.setOnTrimVideoListener(this);
			videoPath = path;
			final String realPath = RealPathUtils.getRealPath(this, Uri.parse(path));
			mBinding.trimmerView.initVideoByURI(Uri.parse(realPath), startMS, endMs);
		}
	}

	@Override
	public void onResume() {
		super.onResume();
	}

	@Override
	public void onPause() {
		super.onPause();
		mBinding.trimmerView.onVideoPause();
		mBinding.trimmerView.setRestoreState(true);
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		mBinding.trimmerView.onDestroy();
	}

	@Override
	public void onStartTrim() {
	}

	@Override
	public void onFinishTrim(String inputFile, long startMs, long endMs) {
		Bundle conData = new Bundle();
		conData.putString(VIDEO_PATH_KEY,videoPath);
		conData.putLong(START_MS_KEY,startMs);
		conData.putLong(END_MS_KEY,endMs);
		Intent intent = new Intent();
		intent.putExtras(conData);
		setResult(RESULT_OK, intent);
		finish();
		//TODO: please handle your trimmed video url here!!!
		//String out = StorageUtil.getCacheDir() + File.separator + COMPRESSED_VIDEO_FILE_NAME;
		//buildDialog(getResources().getString(R.string.compressing)).show();
		//VideoCompressor.compress(this, in, out, new VideoCompressListener() {
		//  @Override public void onSuccess(String message) {
		//  }
		//
		//  @Override public void onFailure(String message) {
		//  }
		//
		//  @Override public void onFinish() {
		//    if (mProgressDialog.isShowing()) mProgressDialog.dismiss();
		//    finish();
		//  }
		//});
	}

	@Override
	public void onCancel() {
		mBinding.trimmerView.onDestroy();
		finish();
	}

//	private ProgressDialog buildDialog(String msg) {
//		if (mProgressDialog == null) {
//			mProgressDialog = ProgressDialog.show(this, "", msg);
//		}
//		mProgressDialog.setMessage(msg);
//		return mProgressDialog;
//	}
}
