package com.maktabah.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.ListView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.documentfile.provider.DocumentFile
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private lateinit var btnSelectFolder: Button
    private lateinit var etSearch: EditText
    private lateinit var tvStatus: TextView
    private lateinit var listViewPdf: ListView

    private val pdfList = mutableListOf<PdfItem>()
    private val displayedList = mutableListOf<String>()
    private lateinit var adapter: ArrayAdapter<String>

    data class PdfItem(val name: String, val uri: Uri)

    private val folderPickerLauncher = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri ->
        uri?.let {
            contentResolver.takePersistableUriPermission(
                it,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            scanFolder(it)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        btnSelectFolder = findViewById(R.id.btnSelectFolder)
        etSearch = findViewById(R.id.etSearch)
        tvStatus = findViewById(R.id.tvStatus)
        listViewPdf = findViewById(R.id.listViewPdf)

        adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, displayedList)
        listViewPdf.adapter = adapter

        btnSelectFolder.setOnClickListener {
            folderPickerLauncher.launch(null)
        }

        listViewPdf.setOnItemClickListener { _, _, position, _ ->
            val selectedPdf = pdfList[position]
            openPdf(selectedPdf.uri)
        }

        etSearch.addTextChangedListener(object : android.text.TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count) {
                filterPdf(s.toString())
            }
            override fun afterTextChanged(s: android.text.Editable?) {}
        })
    }

    private fun scanFolder(uri: Uri) {
        pdfList.clear()
        val rootDir = DocumentFile.fromTreeUri(this, uri)
        if (rootDir != null && rootDir.isDirectory) {
            traverseFolder(rootDir)
        }

        updateDisplayList(pdfList)
        tvStatus.text = "Ditemukan ${pdfList.size} kitab PDF."
        Toast.LENGTH_SHORT.let { Toast.makeText(this, "Pemindaian selesai!", it).show() }
    }

    private fun traverseFolder(dir: DocumentFile) {
        for (file in dir.listFiles()) {
            if (file.isDirectory) {
                traverseFolder(file)
            } else if (file.isFile) {
                val name = file.name ?: ""
                if (name.lowercase(Locale.ROOT).endsWith(".pdf")) {
                    pdfList.add(PdfItem(name, file.uri))
                }
            }
        }
    }

    private fun updateDisplayList(items: List<PdfItem>) {
        displayedList.clear()
        for (item in items) {
            displayedList.add(item.name)
        }
        adapter.notifyDataSetChanged()
    }

    private fun filterPdf(query: String) {
        val filtered = if (query.isEmpty()) {
            pdfList
        } else {
            pdfList.filter { it.name.lowercase(Locale.ROOT).contains(query.lowercase(Locale.ROOT)) }
        }
        updateDisplayList(filtered)
    }

    private fun openPdf(uri: Uri) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            }
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Tidak ada aplikasi pembaca PDF yang terpasang.", Toast.LENGTH_LONG).show()
        }
    }
}
