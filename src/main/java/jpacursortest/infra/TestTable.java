package jpacursortest.infra;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Getter
@Entity
@Table(name = "TEST_TABLE")
public class TestTable {

    @Id
    @Column(name = "ID")
    private String id;

    @Column(name = "NAME")
    private String name;
}
