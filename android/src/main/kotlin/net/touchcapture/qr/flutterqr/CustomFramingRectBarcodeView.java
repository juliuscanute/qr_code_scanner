package net.touchcapture.qr.flutterqr;

import android.content.Context;
import android.graphics.Rect;
import android.util.AttributeSet;

import com.journeyapps.barcodescanner.BarcodeView;
import com.journeyapps.barcodescanner.Size;

public class CustomFramingRectBarcodeView extends BarcodeView {

    private static final int BOTTOM_OFFSET_NOT_SET_VALUE = -1;

    private int bottomOffset = BOTTOM_OFFSET_NOT_SET_VALUE;

    public CustomFramingRectBarcodeView(Context context) {
        super(context);
    }

    public CustomFramingRectBarcodeView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public CustomFramingRectBarcodeView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected Rect calculateFramingRect(Rect container, Rect surface) {
        Rect containerArea = new Rect(container);
        boolean intersects = containerArea.intersect(surface);//adjusts the containerArea (code from super.calculateFramingRect)
        Rect scanAreaRect = super.calculateFramingRect(container, surface);
        if (bottomOffset != BOTTOM_OFFSET_NOT_SET_VALUE) {//if the setFramingRect function was called, then we shift the scan area by Y
            Rect scanAreaRectWithOffset = new Rect(scanAreaRect);
            scanAreaRectWithOffset.bottom -= bottomOffset;
            scanAreaRectWithOffset.top -= bottomOffset;

            boolean belongsToContainer = scanAreaRectWithOffset.intersect(containerArea);
            if(belongsToContainer){
                return scanAreaRectWithOffset;
            }
        }
        return scanAreaRect;
    }

    public void setFramingRect(int rectWidth, int rectHeight, int bottomOffset) {
        this.bottomOffset = bottomOffset;
        this.setFramingRectSize(new Size(rectWidth, rectHeight));
    }
}
