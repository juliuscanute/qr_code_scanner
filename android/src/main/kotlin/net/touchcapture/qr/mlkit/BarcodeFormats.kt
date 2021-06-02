package net.touchcapture.qr.mlkit

import com.google.mlkit.vision.barcode.Barcode
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import java.util.*

enum class BarcodeFormats(val intValue: Int) {
    ALL_FORMATS(Barcode.FORMAT_ALL_FORMATS), CODE_128(Barcode.FORMAT_CODE_128), CODE_39(Barcode.FORMAT_CODE_39), CODE_93(Barcode.FORMAT_CODE_93), CODABAR(Barcode.FORMAT_CODABAR), DATA_MATRIX(Barcode.FORMAT_DATA_MATRIX), EAN_13(Barcode.FORMAT_EAN_13), EAN_8(Barcode.FORMAT_EAN_8), ITF(Barcode.FORMAT_ITF), QR_CODE(Barcode.FORMAT_QR_CODE), UPC_A(Barcode.FORMAT_UPC_A), UPC_E(Barcode.FORMAT_UPC_E), PDF417(Barcode.FORMAT_PDF417), AZTEC(Barcode.FORMAT_AZTEC);

    companion object {
        private var formatsMap: MutableMap<String, Int>? = null

        /**
         * Return the integer value resuling from OR-ing all of the values
         * of the supplied strings.
         *
         *
         * Note that if ALL_FORMATS is defined as well as other values, ALL_FORMATS
         * will be ignored (following how it would work with just OR-ing the ints).
         *
         * @param strings - list of strings representing the various formats
         * @return integer value corresponding to OR of all the values.
         */
        fun intFromStringList(strings: List<String>?): Int {
            if (strings == null) return ALL_FORMATS.intValue
            var `val` = 0
            for (string in strings) {
                val asInt = formatsMap!![string]
                if (asInt != null) {
                    `val` = `val` or asInt
                }
            }
            return `val`
        }

        fun optionsFromStringList(strings: List<String>?): BarcodeScannerOptions {
            if (strings == null) {
                return BarcodeScannerOptions.Builder().setBarcodeFormats(ALL_FORMATS.intValue).build()
            }
            val ints: MutableList<Int> = ArrayList(strings.size)
            run {
                var i = 0
                val l = strings.size
                while (i < l) {
                    val integer = formatsMap!![strings[i]]
                    if (integer != null) {
                        ints.add(integer)
                    }
                    ++i
                }
            }
            if (ints.size == 0) {
                return BarcodeScannerOptions.Builder().setBarcodeFormats(ALL_FORMATS.intValue).build()
            }
            if (ints.size == 1) {
                return BarcodeScannerOptions.Builder().setBarcodeFormats(ints[0]).build()
            }
            val first = ints[0]
            val rest = IntArray(ints.size - 1)
            var i = 0
            for (e in ints.subList(1, ints.size)) {
                rest[i++] = e
            }
            return BarcodeScannerOptions.Builder()
                    .setBarcodeFormats(first, *rest).build()
        }

        init {
            val values: Array<BarcodeFormats> = values()
            formatsMap = HashMap<String, Int>(values().size * 4 / 3)
            for (value in values()) {
                formatsMap!![value.name] = value.intValue
            }
        }
    }
}