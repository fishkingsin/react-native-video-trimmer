
package com.creedon.reactlibrary.videotrimmer;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.annotation.StyleRes;

import com.creedon.androidVideoTrimmer.features.trim.VideoTrimmerActivity;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.tbruyelle.rxpermissions2.RxPermissions;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Iterator;

import iknow.android.utils.BaseUtils;
import io.reactivex.functions.Consumer;

import static android.app.Activity.RESULT_OK;
import static com.creedon.androidVideoTrimmer.features.trim.VideoTrimmerActivity.VIDEO_TRIM_REQUEST_CODE;

public class RNVideoTrimmerModule extends ReactContextBaseJavaModule implements ActivityEventListener {

	private final ReactApplicationContext reactContext;
	private static final String E_ACTIVITY_DOES_NOT_EXIST = "E_ACTIVITY_DOES_NOT_EXIST";
	private static final String NO_RESULT_ERROR = "NO_RESULT_ERROR";
	private static final String PERMISSION_DENIED_ERROR = "PERMISSION_DENIED";
	private static final String PHOTO_LIBRARY_PERMISSIONS_NOT_GRANTED = "Photo library permissions not granted";
	private static final String VIDEO_PATH_KEY = "VIDEO_PATH_KEY";
	private Promise mTrimmerPromise;
	private ReadableMap options;
	private int dialogThemeId;
	public RNVideoTrimmerModule(ReactApplicationContext reactContext, @StyleRes final int dialogThemeId) {
		super(reactContext);
		this.reactContext = reactContext;
		this.reactContext.addActivityEventListener(this);
		BaseUtils.init(this.reactContext);
	}

	public Context getContext() {
		return getReactApplicationContext();
	}

	@SuppressLint("CheckResult")
	@ReactMethod
	public void showVideoTrimmer(ReadableMap options, final Promise promise) {
		this.options = options;
		final Activity activity = getCurrentActivity();
		mTrimmerPromise = promise;
		if (activity == null) {
			promise.reject(E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist");
			return;
		}
		RxPermissions rxPermissions = new RxPermissions(this.getCurrentActivity());
		try {
			rxPermissions.request(Manifest.permission.READ_EXTERNAL_STORAGE).subscribe(new Consumer<Boolean>() {
				@Override
				public void accept(Boolean granted) throws Exception {

					if (granted) {
						Bundle bundle = new Bundle();
						String videoPath = "";
						bundle.putString(VIDEO_PATH_KEY, videoPath);
						Intent intent = new Intent(getReactApplicationContext(), VideoTrimmerActivity.class);
						intent.putExtras(bundle);
						reactContext.startActivityForResult(intent, VIDEO_TRIM_REQUEST_CODE, bundle);
					} else {
						mTrimmerPromise.reject(PERMISSION_DENIED_ERROR, PHOTO_LIBRARY_PERMISSIONS_NOT_GRANTED);
					}
				}
			});
		}catch (Exception exception) {
			mTrimmerPromise.reject(exception);
		}
	}

	@Override
	public String getName() {
		return "RNVideoTrimmer";
	}

	public @NonNull
	Activity getActivity() {
		return getCurrentActivity();
	}


	@Override
	public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
		if (requestCode == VIDEO_TRIM_REQUEST_CODE && resultCode == RESULT_OK && data != null) {
			JSONArray response = new JSONArray();
			try {
				mTrimmerPromise.resolve(convertJsonToArray(response));
			} catch (JSONException e) {
				mTrimmerPromise.reject(e);
			}
		} else {
			mTrimmerPromise.reject(NO_RESULT_ERROR, NO_RESULT_ERROR);
		}
	}

	@Override
	public void onNewIntent(Intent intent) {

	}
	private static WritableMap convertJsonToMap(JSONObject jsonObject) throws JSONException {
		WritableMap map = Arguments.createMap();

		Iterator<String> iterator = jsonObject.keys();
		while (iterator.hasNext()) {
			String key = iterator.next();
			Object value = jsonObject.get(key);
			if (value instanceof JSONObject) {
				map.putMap(key, convertJsonToMap((JSONObject) value));
			} else if (value instanceof JSONArray) {
				map.putArray(key, convertJsonToArray((JSONArray) value));
			} else if (value instanceof Boolean) {
				map.putBoolean(key, (Boolean) value);
			} else if (value instanceof Integer) {
				map.putInt(key, (Integer) value);
			} else if (value instanceof Double) {
				map.putDouble(key, (Double) value);
			} else if (value instanceof String) {
				map.putString(key, (String) value);
			} else {
				map.putString(key, value.toString());
			}
		}
		return map;
	}

	private static WritableArray convertJsonToArray(JSONArray jsonArray) throws JSONException {
		WritableArray array = new WritableNativeArray();

		for (int i = 0; i < jsonArray.length(); i++) {
			Object value = jsonArray.get(i);
			if (value instanceof JSONObject) {
				array.pushMap(convertJsonToMap((JSONObject) value));
			} else if (value instanceof JSONArray) {
				array.pushArray(convertJsonToArray((JSONArray) value));
			} else if (value instanceof Boolean) {
				array.pushBoolean((Boolean) value);
			} else if (value instanceof Integer) {
				array.pushInt((Integer) value);
			} else if (value instanceof Double) {
				array.pushDouble((Double) value);
			} else if (value instanceof String) {
				array.pushString((String) value);
			} else {
				array.pushString(value.toString());
			}
		}
		return array;
	}

	public int getDialogThemeId() {
		return this.dialogThemeId;
	}
}
